//
//  ViewModel.swift
//  DocMate
//
//  Created by Naman Yadav on 23/03/26.
//

import Foundation
import UIKit
import SwiftData

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
    // MARK: - Fetch All from Supabase
    
    // Fetches all data from Supabase and populates local arrays.
    // Call this once on login / app launch.
    @MainActor
    func fetchAll() async {
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
            if !images.isEmpty {
                imageStore[document.id] = images
            }
            await fetchAll()
        } catch {
            print("Add document error: \(error)")
            errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    func deleteDocument(_ document: Document) async {
        do {
            // Delete PDF from Supabase Storage if it exists
            if let path = document.filePath {
                try? await supa.deletePDF(path: path)
            }
            
            // Delete from database
            try await supa.deleteDocument(id: document.id)
            imageStore.removeValue(forKey: document.id)
            await fetchAll()
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
        
        do {
            try await supa.updateDocument(documents[index])
            return true
        } catch {
            print("Toggle pin error: \(error)")
            // Revert on failure
            await fetchAll()
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
        
        // 1. Convert images to PDF
        let pdfData = PDFConverter.makePDF(from: images)
        
        // 2. Create document
        var doc = Document(
            name: name,
            dueDate: dueDate,
            isPinned: false,
            userId: userId,
            categoryId: categoryId,
            fileType: .pdf
        )
        
        do {
            // Check if online. If offline, fail immediately to trigger fallback.
            guard SyncManager.shared.isOnline else {
                throw NSError(domain: "NSURLErrorDomain", code: -1009)
            }
            
            // 3. Upload PDF to Supabase Storage
            let storagePath = try await supa.uploadPDF(
                data: pdfData,
                userId: userId,
                documentId: doc.id
            )
            
            // 4. Store the storage path
            doc.filePath = storagePath
            
            // 5. Insert document metadata into Supabase DB
            try await supa.insertDocument(doc)
            
            // 6. Keep thumbnail in memory for quick preview
            if let first = images.first {
                imageStore[doc.id] = [first]
            }
            // for testing only
            print(" Upload success:", storagePath)
            print(" DB insert success:", doc.id)
            print(" Category:", categoryId)
            print(" User:", userId)
            
            // 7. Refresh
            await fetchAll()
        } catch {
            print("Add scanned document error: \(error). Falling back to offline local save.")
            
            // Fallback: save PDF to cache folder and store metadata in SwiftData
            saveOfflineFallback(
                pdfData: pdfData,
                id: doc.id,
                userId: userId,
                categoryId: categoryId,
                name: name,
                dueDate: dueDate,
                thumbnail: images.first
            )
            
            await fetchAll()
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
        
        let pdfData = PDFConverter.makePDF(from: [image])
        
        var doc = Document(
            name: name,
            isPinned: false,
            userId: userId,
            categoryId: categoryId,
            fileType: .pdf
        )
        
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
            imageStore[doc.id] = [image]
            await fetchAll()
        } catch {
            print("Add photo document error: \(error). Falling back to offline local save.")
            
            // Fallback: save PDF to cache folder and store metadata in SwiftData
            saveOfflineFallback(
                pdfData: pdfData,
                id: doc.id,
                userId: userId,
                categoryId: categoryId,
                name: name,
                dueDate: nil,
                thumbnail: image
            )
            
            await fetchAll()
        }
    }
    
   
    // MARK: - Category CRUD
    @MainActor
    func addCategory(name: String, sfSymbol: String) async {
        guard let userId = await supa.currentUserId else { return }
        
        let cat = Category(name: name, sfSymbol: sfSymbol, userId: userId)
        do {
            try await supa.insertCategory(cat)
            await fetchAll()
        } catch {
            print("Add category error: \(error)")
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func renameCategory(_ category: Category, to newName: String) async {
        do {
            try await supa.updateCategoryName(id: category.id, newName: newName)
            await fetchAll()
        } catch {
            print("Rename category error: \(error)")
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func deleteCategory(_ category: Category) async {
        do {
            try await supa.deleteCategory(id: category.id)
            await fetchAll()
        } catch {
            print("Delete category error: \(error)")
            errorMessage = error.localizedDescription
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
                await fetchAll()
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
    // MARK: - Thumbnail Loader
    // =========================================================
    @MainActor
    private func loadThumbnails(for docs: [Document]) async {
        await withTaskGroup(of: (UUID, UIImage?).self) { group in
            for doc in docs {
                guard imageStore[doc.id] == nil else { continue }
                
                if let path = doc.filePath {
                    group.addTask {
                        guard let data = try? await SupabaseManager.shared.downloadPDF(path: path),
                              let provider = CGDataProvider(data: data as CFData),
                              let pdf = CGPDFDocument(provider),
                              let page = pdf.page(at: 1) else {
                            return (doc.id, nil)
                        }
                        return (doc.id, Self.renderPDFPage(page))
                    }
                } else {
                    let fileName = "\(doc.id.uuidString.lowercased()).pdf"
                    group.addTask {
                        let fileManager = FileManager.default
                        let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
                        let fileURL = cacheDir.appendingPathComponent(fileName)
                        
                        guard fileManager.fileExists(atPath: fileURL.path),
                              let data = try? Data(contentsOf: fileURL),
                              let provider = CGDataProvider(data: data as CFData),
                              let pdf = CGPDFDocument(provider),
                              let page = pdf.page(at: 1) else {
                            return (doc.id, nil)
                        }
                        return (doc.id, Self.renderPDFPage(page))
                    }
                }
            }
            for await (id, img) in group {
                if let img {
                    imageStore[id] = [img]
                }
            }
        }
    }
    
    nonisolated private static func renderPDFPage(_ page: CGPDFPage) -> UIImage? {
        let pageRect = page.getBoxRect(.mediaBox)
        let scale: CGFloat = 0.4
        let width = Int(pageRect.width * scale)
        let height = Int(pageRect.height * scale)
        
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                  data: nil,
                  width: width,
                  height: height,
                  bitsPerComponent: 8,
                  bytesPerRow: 0,
                  space: colorSpace,
                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            return nil
        }
        
        // Fill white background
        context.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        
        // Scale and translate context for PDF drawing
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: scale, y: -scale)
        
        // Draw the PDF page
        context.drawPDFPage(page)
        
        // Create CGImage and UIImage
        guard let cgImage = context.makeImage() else { return nil }
        return UIImage(cgImage: cgImage)
    }
    // MARK: - Rename Document
    @MainActor
    func renameDocument(_ document: Document, to newName: String) async {
        guard let index = documents.firstIndex(where: { $0.id == document.id }) else { return }
        documents[index].name = newName
        do {
            try await supa.updateDocument(documents[index])
        } catch {
            print("Rename error: \(error)")
            await fetchAll()
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
            await fetchAll()
        } catch {
            print("Duplicate error: \(error)")
        }
    }
}
