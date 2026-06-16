//
//  SyncManager.swift
//  DocMate
//
//  Created by Antigravity on 14/06/26.
//

import Foundation
import Network
import SwiftData
import Supabase

@MainActor
final class SyncManager {
    static let shared = SyncManager()
    
    private let monitor = NWPathMonitor()
    private var isMonitoring = false
    
    var isOnline: Bool = false {
        didSet {
            if isOnline {
                print("SyncManager: Device is online. Triggering synchronization...")
                triggerSync()
            } else {
                print("SyncManager: Device is offline.")
            }
        }
    }
    
    private var container: ModelContainer?
    
    private init() {
        self.container = try? ModelContainer(for: LocalDocument.self)
    }
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        monitor.pathUpdateHandler = { path in
            let isSatisfied = (path.status == .satisfied)
            Task { @MainActor in
                SyncManager.shared.isOnline = isSatisfied
            }
        }
        
        let queue = DispatchQueue(label: "com.docmate.syncmonitor")
        monitor.start(queue: queue)
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        monitor.cancel()
        isMonitoring = false
    }
    
    func triggerSync() {
        Task {
            await syncPendingDocuments()
        }
    }
    
    private func syncPendingDocuments() async {
        guard let container = container else {
            print("SyncManager Error: ModelContainer not initialized.")
            return
        }
        
        let context = ModelContext(container)
        
        // Fetch un-synced local documents
        var descriptor = FetchDescriptor<LocalDocument>(
            predicate: #Predicate<LocalDocument> { !$0.isSynced }
        )
        // Sort by creation date ascending
        descriptor.sortBy = [SortDescriptor(\.createdAt, order: .forward)]
        
        guard let pendingDocs = try? context.fetch(descriptor), !pendingDocs.isEmpty else {
            return
        }
        
        print("SyncManager: Found \(pendingDocs.count) pending documents to sync.")
        
        let supa = SupabaseManager.shared
        
        for localDoc in pendingDocs {
            print("SyncManager: Syncing document: \(localDoc.name)")
            
            // 1. Locate the file in cache directory
            guard let localFileName = localDoc.localFileName else {
                print("SyncManager Error: No local file name for \(localDoc.name)")
                continue
            }
            
            let fileManager = FileManager.default
            let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
            let fileURL = cacheDir.appendingPathComponent(localFileName)
            
            guard fileManager.fileExists(atPath: fileURL.path) else {
                print("SyncManager Error: File does not exist at path \(fileURL.path)")
                continue
            }
            
            do {
                // 2. Read the local PDF data
                let pdfData = try Data(contentsOf: fileURL)
                
                // 3. Upload to Supabase Storage
                let storagePath = try await supa.uploadPDF(
                    data: pdfData,
                    userId: localDoc.userId,
                    documentId: localDoc.id
                )
                
                // 4. Create database record
                let doc = Document(
                    id: localDoc.id,
                    name: localDoc.name,
                    dueDate: localDoc.dueDate,
                    isPinned: localDoc.isPinned,
                    userId: localDoc.userId,
                    categoryId: localDoc.categoryId,
                    createdAt: localDoc.createdAt,
                    fileType: localDoc.fileType == "pdf" ? .pdf : .image,
                    filePath: storagePath
                )
                
                try await supa.insertDocument(doc)
                
                // 5. Update sync state
                localDoc.isSynced = true
                try context.save()
                
                print("SyncManager: Successfully synced \(localDoc.name)")
                
                // 6. Notify ViewModel to fetch fresh Supabase data
                NotificationCenter.default.post(name: .docMateDidSyncDocument, object: nil)
                
            } catch {
                print("SyncManager Error: Failed to sync \(localDoc.name) with error: \(error)")
                // Stop syncing subsequent files if we hit a network issue
                break
            }
        }
    }
}

extension Notification.Name {
    static let docMateDidSyncDocument = Notification.Name("docMateDidSyncDocument")
}
