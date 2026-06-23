//
//  ViewModel.swift
//  DocMate
//
//  Created by Naman Yadav on 23/03/26.
//

import Foundation
import UIKit
import SwiftData
import Supabase
import Storage

@Observable
class AppViewModel {
    
    // MARK: - In-Memory Image Store (stays in memory for now)
    var imageStore: [UUID: [UIImage]] = [:]
    
    // MARK: - Gender Options
    var genderOptions: [String] = ["Male", "Female", "Other"]
    
    // MARK: - Max Pinned
    static let maxPinnedDocuments = 5
    
    // MARK: - Expiry Threshold (Days)
    static let expiryThresholdDays = 10
    
    // MARK: - SwiftData Local Cache
    private var localContainer: ModelContainer? = {
        try? ModelContainer(for: LocalDocument.self)
    }()
    
    private var localContext: ModelContext? {
        guard let localContainer = localContainer else { return nil }
        return ModelContext(localContainer)
    }
    
    init() {
        // Load cached categories on launch immediately so they are available synchronously
        if let data = UserDefaults.standard.data(forKey: "cached_categories"),
           let cached = try? JSONDecoder().decode([Category].self, from: data) {
            self.categories = cached
        } else {
            // Default categories as initial fallback
            self.categories = [
                Category(id: UUID(uuidString: "7e50529d-43cf-4c4f-836e-b3de85721111")!, name: "Finance", sfSymbol: "dollarsign.circle"),
                Category(id: UUID(uuidString: "8e50529d-43cf-4c4f-836e-b3de85722222")!, name: "Identity", sfSymbol: "person.circle"),
                Category(id: UUID(uuidString: "9e50529d-43cf-4c4f-836e-b3de85723333")!, name: "Education", sfSymbol: "book.circle"),
                Category(id: UUID(uuidString: "ae50529d-43cf-4c4f-836e-b3de85724444")!, name: "Vehicle", sfSymbol: "car.side"),
                Category(id: UUID(uuidString: "be50529d-43cf-4c4f-836e-b3de85725555")!, name: "Service Bills", sfSymbol: "house"),
                Category(id: UUID(uuidString: "ce50529d-43cf-4c4f-836e-b3de85726666")!, name: "Policies", sfSymbol: "doc"),
                Category(id: UUID(uuidString: "de50529d-43cf-4c4f-836e-b3de85727777")!, name: "Other", sfSymbol: "questionmark.circle")
            ]
        }
        
        // Load cached documents on launch immediately so they are available synchronously
        if let data = UserDefaults.standard.data(forKey: "cached_documents"),
           let cached = try? JSONDecoder().decode([Document].self, from: data) {
            self.documents = cached
        }

        NotificationCenter.default.addObserver(
            forName: .docMateDidSyncDocument,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.fetchAll()
            }
        }
    }
    
    // MARK: - Loading & Error State
    var isLoading = false
    var errorMessage: String?
    
    // MARK: - Stored Data (populated from Supabase)

    var categories: [Category] = []
    var documents: [Document] = []
    var tags: [Tag] = []
    var allBills: [Infetch] = []
    
    private var _user: User?
    var user: User {
        _user ?? User(
            name: "",
            dateOfBirth: nil,
            gender: nil
        )    }
    
    // MARK: - Unpaid Bills (computed from stored allBills)
    var inFetch: [Infetch] {
        allBills.filter { !$0.isPaid }
    }
    
    // MARK: - Paid Bills (computed from stored allBills)
    var billHistory: [Infetch] {
        allBills.filter { $0.isPaid }
    }
    
 
    // MARK: - Supabase Helper
    private let supa = SupabaseManager.shared

    // Coalescing guards so rapid duplicate refreshes (e.g. RootView + ContentView
    // on launch, or one-per-doc sync callbacks) don't each re-download everything.
    @ObservationIgnored private var isFetchingAll = false
    @ObservationIgnored private var lastFetchAllAt: Date?

    // MARK: - Fetch All from Supabase

    // Fetches all data from Supabase and populates local arrays.
    // Call this once on login / app launch. Pass `force: true` for an explicit
    // user-initiated refresh (e.g. pull-to-refresh).
    @MainActor
    func fetchAll(force: Bool = false) async {
        // Skip if a fetch is already running, or one completed very recently.
        if isFetchingAll { return }
        if !force, let last = lastFetchAllAt, Date().timeIntervalSince(last) < 3 {
            return
        }
        isFetchingAll = true
        defer {
            isFetchingAll = false
            lastFetchAllAt = Date()
        }

        isLoading = true
        errorMessage = nil

        // Fetch each independently so one failure doesn't block the rest
        do {
            _user = try await supa.fetchProfile()
        } catch {
            print(" Profile fetch error: \(error)")
        }
        
        do {
            let fetchedCategories = try await supa.fetchCategories()
            categories = fetchedCategories
            if let data = try? JSONEncoder().encode(fetchedCategories) {
                UserDefaults.standard.set(data, forKey: "cached_categories")
            }
        } catch {
            print(" Categories fetch error: \(error)")
            if let data = UserDefaults.standard.data(forKey: "cached_categories"),
               let cached = try? JSONDecoder().decode([Category].self, from: data) {
                categories = cached
                print("Loaded categories from local cache fallback.")
            } else {
                // Default fallback categories
                categories = [
                    Category(id: UUID(uuidString: "7e50529d-43cf-4c4f-836e-b3de85721111")!, name: "Finance", sfSymbol: "dollarsign.circle"),
                    Category(id: UUID(uuidString: "8e50529d-43cf-4c4f-836e-b3de85722222")!, name: "Identity", sfSymbol: "person.circle"),
                    Category(id: UUID(uuidString: "9e50529d-43cf-4c4f-836e-b3de85723333")!, name: "Education", sfSymbol: "book.circle"),
                    Category(id: UUID(uuidString: "ae50529d-43cf-4c4f-836e-b3de85724444")!, name: "Vehicle", sfSymbol: "car.side"),
                    Category(id: UUID(uuidString: "be50529d-43cf-4c4f-836e-b3de85725555")!, name: "Service Bills", sfSymbol: "house"),
                    Category(id: UUID(uuidString: "ce50529d-43cf-4c4f-836e-b3de85726666")!, name: "Policies", sfSymbol: "doc"),
                    Category(id: UUID(uuidString: "de50529d-43cf-4c4f-836e-b3de85727777")!, name: "Other", sfSymbol: "questionmark.circle")
                ]
                print("No cached categories found. Loaded default categories.")
            }
        }
        
        do {
            let fetchedDocs = try await supa.fetchDocuments()
            documents = fetchedDocs
            if let data = try? JSONEncoder().encode(fetchedDocs) {
                UserDefaults.standard.set(data, forKey: "cached_documents")
            }
        } catch {
            print(" Documents fetch error: \(error)")
            if let data = UserDefaults.standard.data(forKey: "cached_documents"),
               let cached = try? JSONDecoder().decode([Document].self, from: data) {
                documents = cached
                print("Loaded documents from local cache fallback.")
            } else {
                documents = []
            }
        }
        
        // Append local un-synced documents
        if let context = localContext {
            let descriptor = FetchDescriptor<LocalDocument>(
                predicate: #Predicate<LocalDocument> { !$0.isSynced }
            )
            if let localDocs = try? context.fetch(descriptor) {
                let mapped = localDocs.map { local in
                    Document(
                        id: local.id,
                        name: local.name,
                        dueDate: local.dueDate,
                        isPinned: local.isPinned,
                        userId: local.userId,
                        categoryId: local.categoryId,
                        createdAt: local.createdAt,
                        fileType: .pdf,
                        filePath: nil
                    )
                }
                documents.append(contentsOf: mapped)
            }
        }
        
        do {
            tags = try await supa.fetchTags()
        } catch {
            print(" Tags fetch error: \(error)")
        }
        
        do {
            allBills = try await supa.fetchBills()
        } catch {
            print(" Bills fetch error: \(error)")
        }
        
        NotificationManager.shared.removeAll()
// MARK: for tested only
//        for doc in documents {
//            NotificationManager.shared.scheduleExpiryReminder(for: doc)
//        }
        
        for doc in documents where doc.dueDate != nil {
            NotificationManager.shared.scheduleExpiryReminder(for: doc)
        }
        
        isLoading = false
    }
    // MARK: - Seed Default Categories (first login only)
    // Seeds default categories for a new user if they have none.
    @MainActor
    func seedIfNeeded() async {
        guard let userId = await supa.currentUserId else { return }
        
        do {
            let existingCats = try await supa.fetchCategories()
            guard existingCats.isEmpty else { return }
            
            let defaults: [(String, String)] = [
                ("Finance",       "dollarsign.circle"),
                ("Identity",      "person.circle"),
                ("Education",     "book.circle"),
                ("Vehicle",       "car.side"),
                ("Service Bills", "house"),
                ("Policies",      "doc"),
                ("Other",         "questionmark.circle"),
            ]
            
            for (name, symbol) in defaults {
                let cat = Category(name: name, sfSymbol: symbol, userId: userId)
                try await supa.insertCategory(cat)
            }
            
            // Refresh after seeding
            categories = try await supa.fetchCategories()
        } catch {
            print("Seed error: \(error)")
        }
    }

    // MARK: - Category Helpers
    func category(named name: String) -> Category? {
        categories.first { $0.name == name }
    }
    
    func icon(for document: Document) -> String {
        categories.first(where: { $0.id == document.categoryId })?.sfSymbol ?? "doc.text"
    }
    
  
    // MARK: - Document Computed Properties
    var expiringDocuments: [Document] {
        let cal = Calendar.current
        let startOfToday = cal.startOfDay(for: Date())
        let threshold = cal.date(byAdding: .day,
                                 value: AppViewModel.expiryThresholdDays,
                                 to: startOfToday)!
        return documents
            .filter {
                guard let due = $0.dueDate else { return false }
                return due >= startOfToday && due <= threshold
            }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }
    
    var overdueDocuments: [Document] {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        return documents
            .filter {
                guard let due = $0.dueDate else { return false }
                return due < startOfToday
            }
            .sorted { ($0.dueDate ?? .distantPast) > ($1.dueDate ?? .distantPast) }
    }

    var recentDocuments: [Document] {
        documents.sorted { $0.createdAt > $1.createdAt }
    }
    
    var pinnedDocuments: [Document] {
        documents.filter { $0.isPinned }
    }
    
    
    // MARK: - Document CRUD
   
    
    @MainActor
    func addDocument(_ document: Document, images: [UIImage] = []) async {
        do {
            try await supa.insertDocument(document)
            registerSavedDocument(document, thumbnail: images.first)
        } catch {
            print("Add document error: \(error)")
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func deleteDocument(_ document: Document) async {
        do {
            // Delete PDF + thumbnail from Supabase Storage if they exist
            if let path = document.filePath {
                try? await supa.deleteStoredFiles(pdfPath: path)
            }

            // Delete from database
            try await supa.deleteDocument(id: document.id)

            // Local cleanup — no full refetch needed.
            imageStore.removeValue(forKey: document.id)
            documents.removeAll { $0.id == document.id }
            removeLocalCachedFiles(for: document.id)
            cacheDocumentsLocally()
        } catch {
            print("Delete document error: \(error)")
            errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    @discardableResult
    func togglePin(_ document: Document) async -> Bool {
        guard let index = documents.firstIndex(where: { $0.id == document.id }) else { return false }
        
        if documents[index].isPinned {
            documents[index].isPinned = false
        } else {
            guard pinnedDocuments.count < AppViewModel.maxPinnedDocuments else { return false }
            documents[index].isPinned = true
        }
        
        let previousState = !documents[index].isPinned
        do {
            try await supa.updateDocument(documents[index])
            cacheDocumentsLocally()
            return true
        } catch {
            print("Toggle pin error: \(error)")
            // Revert locally on failure — no full refetch.
            documents[index].isPinned = previousState
            return false
        }
    }
    
    func documents(for category: Category) -> [Document] {
        documents.filter { $0.categoryId == category.id }
    }
    
    func documentCount(for category: Category) -> Int {
        documents(for: category).count
    }
    
    func images(for document: Document) -> [UIImage] {
        imageStore[document.id] ?? []
    }
    
    @MainActor
    func addScannedDocument(images: [UIImage], name: String, categoryId: UUID, dueDate: Date? = nil) async {
        guard let userId = await supa.currentUserId else { return }

        // 1. Convert images to PDF off the main actor so the UI doesn't freeze.
        let pdfData = await Task.detached(priority: .userInitiated) {
            PDFConverter.makePDF(from: images)
        }.value

        // 2. Create document
        let doc = Document(
            name: name,
            dueDate: dueDate,
            isPinned: false,
            userId: userId,
            categoryId: categoryId,
            fileType: .pdf
        )

        // 3. Show it immediately (optimistic insert) and let the caller dismiss
        //    right away — no full server refetch, no waiting on the network.
        registerSavedDocument(doc, thumbnail: images.first)

        // 4. Upload + persist in the background. On failure it falls back to a
        //    local offline save that SyncManager retries later.
        Task {
            await self.persistDocument(
                doc,
                pdfData: pdfData,
                userId: userId,
                categoryId: categoryId,
                name: name,
                dueDate: dueDate,
                thumbnail: images.first
            )
        }
    }

    /// Optimistically inserts/updates a document in the in-memory list and
    /// cache so it appears instantly, without a full `fetchAll()` round-trip.
    @MainActor
    private func registerSavedDocument(_ doc: Document, thumbnail: UIImage?) {
        documents.removeAll { $0.id == doc.id }
        documents.insert(doc, at: 0)
        cacheDocumentsLocally()

        if let thumbnail {
            imageStore[doc.id] = [thumbnail]
        }

        if doc.dueDate != nil {
            NotificationManager.shared.scheduleExpiryReminder(for: doc)
        }
    }

    /// Persists the current `documents` list to the local cache.
    @MainActor
    private func cacheDocumentsLocally() {
        if let data = try? JSONEncoder().encode(documents) {
            UserDefaults.standard.set(data, forKey: "cached_documents")
        }
    }

    /// Removes a document's locally cached PDF and durable thumbnail.
    @MainActor
    private func removeLocalCachedFiles(for id: UUID) {
        let idStr = id.uuidString.lowercased()
        let fileManager = FileManager.default

        let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        try? fileManager.removeItem(at: cacheDir.appendingPathComponent("\(idStr).pdf"))

        if let appSupport = try? fileManager.url(for: .applicationSupportDirectory,
                                                 in: .userDomainMask,
                                                 appropriateFor: nil,
                                                 create: false) {
            let thumb = appSupport
                .appendingPathComponent("Thumbnails", isDirectory: true)
                .appendingPathComponent("thumb_\(idStr).jpg")
            try? fileManager.removeItem(at: thumb)
        }
    }

    /// Uploads the PDF and inserts metadata. Runs in the background; on any
    /// failure it saves locally for SyncManager to retry.
    @MainActor
    private func persistDocument(
        _ doc: Document,
        pdfData: Data,
        userId: UUID,
        categoryId: UUID,
        name: String,
        dueDate: Date?,
        thumbnail: UIImage?
    ) async {
        var doc = doc
        do {
            // Check if online. If offline, fail immediately to trigger fallback.
            guard SyncManager.shared.isOnline else {
                throw NSError(domain: "NSURLErrorDomain", code: -1009)
            }

            let storagePath = try await supa.uploadPDF(
                data: pdfData,
                userId: userId,
                documentId: doc.id
            )
            doc.filePath = storagePath

            try await supa.insertDocument(doc)

            // Upload a tiny thumbnail alongside the PDF so browsing never has to
            // download the full file. Best-effort — don't fail the save on it.
            if let thumbnail, let thumbData = PDFConverter.thumbnailJPEG(from: thumbnail) {
                _ = try? await supa.uploadThumbnail(data: thumbData, userId: userId, documentId: doc.id)
            }

            // Update the in-memory copy with its remote file path.
            registerSavedDocument(doc, thumbnail: thumbnail)
            print(" Upload success:", storagePath)
        } catch {
            print("Persist document error: \(error). Falling back to offline local save.")
            saveOfflineFallback(
                pdfData: pdfData,
                id: doc.id,
                userId: userId,
                categoryId: categoryId,
                name: name,
                dueDate: dueDate,
                thumbnail: thumbnail
            )
        }
    }
    
    @MainActor
    private func saveOfflineFallback(
        pdfData: Data,
        id: UUID,
        userId: UUID,
        categoryId: UUID,
        name: String,
        dueDate: Date?,
        thumbnail: UIImage?
    ) {
        let fileName = "\(id.uuidString.lowercased()).pdf"
        let fileManager = FileManager.default
        let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let fileURL = cacheDir.appendingPathComponent(fileName)
        
        do {
            // 1. Save PDF file to cache directory
            try pdfData.write(to: fileURL)
            
            // 2. Insert to SwiftData LocalDocument
            if let context = localContext {
                let localDoc = LocalDocument(
                    id: id,
                    userId: userId,
                    categoryId: categoryId,
                    name: name,
                    dueDate: dueDate,
                    isPinned: false,
                    fileType: "pdf",
                    localFileName: fileName,
                    isSynced: false,
                    createdAt: Date()
                )
                context.insert(localDoc)
                try context.save()
                
                // 3. Keep thumbnail in memory for quick preview
                if let thumbnail = thumbnail {
                    imageStore[id] = [thumbnail]
                }
                
                print("Offline fallback: Saved \(name) locally to caches and SwiftData.")
            }
        } catch {
            print("Offline fallback error: \(error)")
            errorMessage = "Failed to save offline: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    func addPhotoDocument(image: UIImage, name: String, categoryId: UUID) async {
        guard let userId = await supa.currentUserId else { return }

        // Build the PDF off the main actor so the UI doesn't freeze.
        let pdfData = await Task.detached(priority: .userInitiated) {
            PDFConverter.makePDF(from: [image])
        }.value

        let doc = Document(
            name: name,
            isPinned: false,
            userId: userId,
            categoryId: categoryId,
            fileType: .pdf
        )

        // Show immediately, upload in the background.
        registerSavedDocument(doc, thumbnail: image)

        Task {
            await self.persistDocument(
                doc,
                pdfData: pdfData,
                userId: userId,
                categoryId: categoryId,
                name: name,
                dueDate: nil,
                thumbnail: image
            )
        }
    }
    
   
    // MARK: - Category CRUD
    @MainActor
    func addCategory(name: String, sfSymbol: String) async {
        guard let userId = await supa.currentUserId else { return }
        
        let cat = Category(name: name, sfSymbol: sfSymbol, userId: userId)
        do {
            try await supa.insertCategory(cat)
            categories.append(cat)
            cacheCategoriesLocally()
        } catch {
            print("Add category error: \(error)")
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func renameCategory(_ category: Category, to newName: String) async {
        do {
            try await supa.updateCategoryName(id: category.id, newName: newName)
            if let index = categories.firstIndex(where: { $0.id == category.id }) {
                categories[index].name = newName
            }
            cacheCategoriesLocally()
        } catch {
            print("Rename category error: \(error)")
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func deleteCategory(_ category: Category) async {
        do {
            try await supa.deleteCategory(id: category.id)
            categories.removeAll { $0.id == category.id }
            cacheCategoriesLocally()
        } catch {
            print("Delete category error: \(error)")
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func cacheCategoriesLocally() {
        if let data = try? JSONEncoder().encode(categories) {
            UserDefaults.standard.set(data, forKey: "cached_categories")
        }
    }
    
    // =========================================================
    // MARK: - User Profile
    // =========================================================
    
    @MainActor
    func updateUser(name: String, dateOfBirth: Date, gender: String) async {
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        var updated = user
        updated.name = name
        updated.dateOfBirth = formatter.string(from: dateOfBirth)
        updated.gender = gender

        do {
            try await supa.updateProfile(updated)
            _user = updated
        } catch {
            print("Update user error: \(error)")
            errorMessage = error.localizedDescription
        }
    }
    // =========================================================
        // MARK: - Bill Operations
        // =========================================================
        @MainActor
        func toggleBillStatus(_ bill: Infetch) async {

            guard let index = allBills.firstIndex(where: { $0.id == bill.id }) else { return }

            allBills[index].isPaid.toggle()

            if allBills[index].isPaid {
                allBills[index].paidAt = Date()
            } else {
                allBills[index].paidAt = nil
            }

            do {
                try await supa.updateBill(allBills[index])
            } catch {
                print("Toggle bill error:", error)
                // Revert locally on failure — no full refetch.
                allBills[index].isPaid.toggle()
                allBills[index].paidAt = allBills[index].isPaid ? Date() : nil
            }
        }

    /// Returns total amount paid within the given month filter.
    func totalSpend(for filter: BillMonthFilter) -> Double {
        billsFiltered(by: filter)
            .compactMap { $0.amount }
            .reduce(0, +)
    }
    
    func billsFiltered(by filter: BillMonthFilter) -> [Infetch] {
        let calendar = Calendar.current
        let reference = filter.referenceDate
        return billHistory.filter { bill in
            calendar.isDate(bill.dueDate, equalTo: reference, toGranularity: .month)
        }
    }
    
    
    @MainActor
    func syncBillsFromGmail() async {
        guard let userId = await supa.currentUserId else { return }

        do {
            errorMessage = nil

            let emails = try await GmailService.shared.fetchBillEmails()

            for email in emails {

                // Only import unpaid bills that are still due (future payments).
                // Paid receipts / past-due emails return nil and are skipped.
                guard let bill = BillParser.makeBill(
                    from: email,
                    userId: userId
                ) else {
                    continue
                }

                let exists = try await supa.billExists(
                    messageId: email.id
                )
                if exists {
                    continue
                }

                try await supa.insertBill(bill)
            }

            await fetchAll()

        } catch {
            print("Gmail Sync Error:", error)
            errorMessage = "Unable to sync bills."
        }
    }
    
 
    @MainActor
    func reset() {
        _user = nil
        categories = []
        documents = []
        tags = []
        allBills = []
        errorMessage = nil
        isLoading = false
    }
    // =========================================================
    // MARK: - Thumbnail Backfill
    // =========================================================

    /// Uploads a small thumbnail for an existing remote document that doesn't
    /// have one yet (legacy docs created before thumbnails existed). Best-effort
    /// — this is what makes the migration self-healing and one-time per doc.
    @MainActor
    func backfillThumbnail(for document: Document, image: UIImage) async {
        guard document.filePath != nil,
              SyncManager.shared.isOnline,
              let userId = await supa.currentUserId,
              let data = PDFConverter.thumbnailJPEG(from: image) else { return }

        _ = try? await supa.uploadThumbnail(data: data, userId: userId, documentId: document.id)
    }
    // MARK: - Rename Document
    @MainActor
    func renameDocument(_ document: Document, to newName: String) async {
        guard let index = documents.firstIndex(where: { $0.id == document.id }) else { return }
        let previousName = documents[index].name
        documents[index].name = newName
        do {
            try await supa.updateDocument(documents[index])
            cacheDocumentsLocally()
        } catch {
            print("Rename error: \(error)")
            // Revert locally on failure — no full refetch.
            documents[index].name = previousName
        }
    }

    // MARK: - Duplicate Document
    @MainActor
    func duplicateDocument(_ document: Document) async {
        guard let userId = await supa.currentUserId else { return }
        let copy = Document(
            name: document.name + " Copy",
            dueDate: document.dueDate,
            isPinned: false,
            userId: userId,
            categoryId: document.categoryId,
            fileType: document.fileTypeEnum
        )
        do {
            try await supa.insertDocument(copy)
            registerSavedDocument(copy, thumbnail: imageStore[document.id]?.first)
        } catch {
            print("Duplicate error: \(error)")
        }
    }
    
    // MARK: - Update Document File
    @MainActor
    func updateDocumentFile(document: Document, pdfData: Data, newThumbnail: UIImage?) async {
        guard let userId = await supa.currentUserId else { return }
        
        let fileName = "\(document.id.uuidString.lowercased()).pdf"
        let fileManager = FileManager.default
        let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let cachedFileURL = cacheDir.appendingPathComponent(fileName)
        
        do {
            try pdfData.write(to: cachedFileURL)
        } catch {
            print("Failed to save edited PDF locally: \(error)")
        }
        
        if let newThumbnail {
            imageStore[document.id] = [newThumbnail]
        }
        
        if let storagePath = document.filePath, !storagePath.isEmpty {
            do {
                try await supa.client.storage
                    .from("documents")
                    .update(
                        storagePath,
                        data: pdfData,
                        options: .init(contentType: "application/pdf")
                    )
                print("Uploaded updated PDF successfully to \(storagePath)")
            } catch {
                print("Failed to upload updated PDF: \(error). Trying delete and upload...")
                try? await supa.deletePDF(path: storagePath)
                _ = try? await supa.uploadPDF(data: pdfData, userId: userId, documentId: document.id)
            }
        } else {
            do {
                let storagePath = try await supa.uploadPDF(
                    data: pdfData,
                    userId: userId,
                    documentId: document.id
                )
                var updatedDoc = document
                updatedDoc.filePath = storagePath
                try await supa.updateDocument(updatedDoc)

                // Reflect the new file path locally — no full refetch.
                if let index = documents.firstIndex(where: { $0.id == document.id }) {
                    documents[index].filePath = storagePath
                    cacheDocumentsLocally()
                }
            } catch {
                print("Failed to save as new PDF: \(error)")
            }
        }

        // The file changed, so refresh the stored thumbnail too (best-effort).
        if let newThumbnail, let thumbData = PDFConverter.thumbnailJPEG(from: newThumbnail) {
            _ = try? await supa.uploadThumbnail(data: thumbData, userId: userId, documentId: document.id)
            // Overwrite the durable on-disk thumbnail with the new one.
            writeDurableThumbnail(thumbData, for: document.id)
            imageStore[document.id] = [newThumbnail]
        }
    }

    /// Durable thumbnail file location (Application Support/Thumbnails).
    @MainActor
    private func durableThumbnailURL(for id: UUID) -> URL {
        let fileManager = FileManager.default
        let base = (try? fileManager.url(for: .applicationSupportDirectory,
                                         in: .userDomainMask,
                                         appropriateFor: nil,
                                         create: true))
            ?? fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("Thumbnails", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("thumb_\(id.uuidString.lowercased()).jpg")
    }

    @MainActor
    private func writeDurableThumbnail(_ data: Data, for id: UUID) {
        try? data.write(to: durableThumbnailURL(for: id))
    }
}

