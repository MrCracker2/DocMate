//
//  ViewModel.swift
//  DocMate
//
//  Created by Naman Yadav on 23/03/26.
//

import Foundation
import UIKit

@Observable
class AppViewModel {
    
    // MARK: - In-Memory Image Store (stays in memory for now)
    var imageStore: [UUID: [UIImage]] = [:]
    
    // MARK: - Gender Options
    var genderOptions: [String] = ["Male", "Female", "Other"]
    
    // MARK: - Max Pinned
    static let maxPinnedDocuments = 5
    
    // MARK: - Loading & Error State
    var isLoading = false
    var errorMessage: String?
    
    // =========================================================
    // MARK: - Stored Data (populated from Supabase)
    // =========================================================
    
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
    
    // =========================================================
    // MARK: - Supabase Helper
    // =========================================================
    
    private let supa = SupabaseManager.shared
    
    // =========================================================
    // MARK: - Fetch All from Supabase
    // =========================================================
    
    /// Fetches all data from Supabase and populates local arrays.
    /// Call this once on login / app launch.
    @MainActor
    func fetchAll() async {
        isLoading = true
        errorMessage = nil
        
        // Fetch each independently so one failure doesn't block the rest
        do {
            _user = try await supa.fetchProfile()
        } catch {
            print("⚠️ Profile fetch error: \(error)")
        }
        
        do {
            categories = try await supa.fetchCategories()
        } catch {
            print("⚠️ Categories fetch error: \(error)")
        }
        
        do {
            documents = try await supa.fetchDocuments()
        } catch {
            print("⚠️ Documents fetch error: \(error)")
        }
        
        do {
            tags = try await supa.fetchTags()
        } catch {
            print("⚠️ Tags fetch error: \(error)")
        }
        
        do {
            allBills = try await supa.fetchBills()
        } catch {
            print("⚠️ Bills fetch error: \(error)")
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
    
    // =========================================================
    // MARK: - Seed Default Categories (first login only)
    // =========================================================
    
    /// Seeds default categories for a new user if they have none.
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
    
    // =========================================================
    // MARK: - Category Helpers
    // =========================================================
    
    func category(named name: String) -> Category? {
        categories.first { $0.name == name }
    }
    
    func icon(for document: Document) -> String {
        categories.first(where: { $0.id == document.categoryId })?.sfSymbol ?? "doc.text"
    }
    
    // =========================================================
    // MARK: - Document Computed Properties
    // =========================================================
    
    var expiringDocuments: [Document] {
        let now = Date()
        let tenDaysLater = now.addingTimeInterval(86400 * 10)
        return documents
            .filter {
                guard let due = $0.dueDate else { return false }
                return due >= now && due <= tenDaysLater
            }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }
    
    var recentDocuments: [Document] {
        documents.sorted { $0.createdAt > $1.createdAt }
    }
    
    var pinnedDocuments: [Document] {
        documents.filter { $0.isPinned }
    }
    
    // =========================================================
    // MARK: - Document CRUD
    // =========================================================
    
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
            print("✅ Upload success:", storagePath)
            print("✅ DB insert success:", doc.id)
            print("✅ Category:", categoryId)
            print("✅ User:", userId)
            
            // 7. Refresh
            await fetchAll()
        } catch {
            if let path = doc.filePath {
                try? await supa.deletePDF(path: path)
            }

            print("Add scanned document error:", error)
            errorMessage = error.localizedDescription
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
            print("Add photo document error: \(error)")
            errorMessage = error.localizedDescription
        }
    }
    
    // =========================================================
    // MARK: - Category CRUD
    // =========================================================
    
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
    func markBillAsPaid(_ bill: Infetch) async {
        guard let index = allBills.firstIndex(where: { $0.id == bill.id }) else { return }

        allBills[index].isPaid = true
        allBills[index].paidAt = Date()

        do {
            try await supa.updateBill(allBills[index])
        } catch {
            print("Mark paid error: \(error)")
            await fetchAll()
        }
    }
    /// Simulates an API call. On success marks bill as paid.
    func refreshBill(_ bill: Infetch, completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let self else { return }
            let isPaid = Bool.random()
            
            if isPaid {
                Task { @MainActor in
                    await self.markBillAsPaid(bill)
                }
            }
            completion(isPaid)
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
    
    // =========================================================
    // MARK: - Gmail Bill Sync
    // =========================================================
    /// Marks a bill as paid and syncs to Supabase.
//    @MainActor
//    func syncBillsFromGmail() async {
//        guard let userId = await supa.currentUserId else { return }
//
//        do {
//            errorMessage = nil
//
//            let emails = try await GmailService.shared.fetchBillEmails()
//
//            for email in emails {
//
//                let exists = try await supa.billExists(
//                    messageId: email.id
//                )
//
//                if exists {
//                    continue
//                }
//
//                let bill = BillParser.makeBill(
//                    from: email,
//                    userId: userId
//                )
//
//                try await supa.insertBill(bill)
//            }
//            // Refresh all local data
//            await fetchAll()
//
//        } catch {
//            print("Gmail Sync Error:", error)
//            errorMessage = "Unable to sync bills."
//        }
//    }
    
    // t
    @MainActor
    func syncBillsFromGmail() async {
        guard let userId = await supa.currentUserId else { return }

        do {
            errorMessage = nil

            let emails = try await GmailService.shared.fetchBillEmails()

            for email in emails {

                let bill = BillParser.makeBill(
                    from: email,
                    userId: userId
                )

                try await supa.insertBill(bill)
            }

            await fetchAll()

        } catch {
            print("Gmail Sync Error:", error)
            errorMessage = "Unable to sync bills."
        }
    }
    
    func makeBillFromGemini(
        _ data: ExtractedBill?,
        email: GmailEmail,
        userId: UUID
    ) -> Infetch {

        let vendor = data?.vendorName ?? "Bill"
        let amount = data?.amount

        let dueDate = parseDateString(data?.dueDate) ?? Calendar.current.date(byAdding: .day, value: 7, to: Date())!

        let billDate = parseDateString(data?.billDate) ?? email.receivedAt

        let category = mapCategory(data?.category ?? "bill")

        return Infetch(
            name: vendor,
            dueDate: dueDate,
            billDate: billDate,
            SubjectName: vendor,
            amount: amount,
            customerName: "",
            phoneNumber: nil,
            billNumber: email.id,
            isPaid: false,
            gmailMessageId: email.id,
            paidAt: nil,
            inFetchCatgogry: category,
            userId: userId
        )
    }
    func parseDateString(_ text: String?) -> Date? {
        guard let text else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: text)
    }

    func mapCategory(_ value: String) -> InfetchCategory {
        switch value.lowercased() {
        case "insurance": return .insurance
        case "finance": return .finance
        case "policy": return .policy
        default: return .bill
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
}
