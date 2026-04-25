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

    // =========================================================
    // MARK: - Stored Data (in-memory arrays)
    // =========================================================

    var categories: [Category] = []
    var documents: [Document] = []
    var tags: [Tag] = []
    var allBills: [Infetch] = []

    private var _user: User?
    var user: User {
        _user ?? User(
            name: "Guest",
            email: "",
            password: "",
            phoneNumber: 0,
            dateOfBirth: Date(),
            gender: "Male"
        )
    }

    func updateUser(name: String, dateOfBirth: Date, gender: String) {
        _user?.name = name
        _user?.dateOfBirth = dateOfBirth
        _user?.gender = gender
    }

    // MARK: - Unpaid Bills (computed from stored allBills)
    var inFetch: [Infetch] {
        allBills.filter { !$0.isPaid }
    }

    // MARK: - Paid Bills (computed from stored allBills)
    var billHistory: [Infetch] {
        allBills.filter { $0.isPaid }
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

    func addDocument(_ document: Document, images: [UIImage] = []) {
        documents.append(document)
        if !images.isEmpty {
            imageStore[document.id] = images
        }
    }

    func deleteDocument(_ document: Document) {
        // Delete PDF file from disk
        if let path = document.filePath {
            try? FileManager.default.removeItem(atPath: path)
        }
        
        documents.removeAll { $0.id == document.id }
        imageStore.removeValue(forKey: document.id)
    }


    @discardableResult
    func togglePin(_ document: Document) -> Bool {
        guard let index = documents.firstIndex(where: { $0.id == document.id }) else { return false }

        if documents[index].isPinned {
            documents[index].isPinned = false
            return true
        } else {
            guard pinnedDocuments.count < AppViewModel.maxPinnedDocuments else { return false }
            documents[index].isPinned = true
            return true
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

    func addScannedDocument(images: [UIImage], name: String, categoryId: UUID, dueDate: Date? = nil) {
        // 1. Convert images to PDF
        let pdfData = PDFConverter.makePDF(from: images)
        
        // 2. Create document
        var doc = Document(
            name: name,
            dueDate: dueDate,
            isPinned: false,
            userId: user.id,
            categoryId: categoryId,
            fileType: .pdf
        )
        
        // 3. Save PDF to disk
        ensureDirectoryExists()
        let fileURL = documentsDirectory().appendingPathComponent("\(doc.id).pdf")
        try? pdfData.write(to: fileURL)
        
        // 4. Store path in document
        doc.filePath = fileURL.path
        
        // 5. Add to array
        documents.append(doc)
        
        // 6. Keep thumbnail in memory for quick preview
        if let first = images.first {
            imageStore[doc.id] = [first]
        }
    }


    func addPhotoDocument(image: UIImage, name: String, categoryId: UUID) {
        let pdfData = PDFConverter.makePDF(from: [image])
        
        var doc = Document(
            name: name,
            isPinned: false,
            userId: user.id,
            categoryId: categoryId,
            fileType: .pdf
        )
        
        ensureDirectoryExists()
        let fileURL = documentsDirectory().appendingPathComponent("\(doc.id).pdf")
        try? pdfData.write(to: fileURL)
        doc.filePath = fileURL.path
        
        documents.append(doc)
        imageStore[doc.id] = [image]
    }

    // Create a helper to get the save folder
    private func documentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ScannedPDFs", isDirectory: true)
    }

    private func ensureDirectoryExists() {
        let dir = documentsDirectory()
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }


    // =========================================================
    // MARK: - Category CRUD
    // =========================================================

    func addCategory(name: String, sfSymbol: String) {
        let cat = Category(name: name, sfSymbol: sfSymbol)
        categories.append(cat)
    }

    // =========================================================
    // MARK: - Bill Operations
    // =========================================================

    /// Simulates an API call. On success marks bill as paid.
    func refreshBill(_ bill: Infetch, completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let self else { return }
            let isPaid = Bool.random()

            if isPaid, let index = allBills.firstIndex(where: { $0.id == bill.id }) {
                allBills[index].isPaid = true
                allBills[index].dueDate = Date()
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
    // MARK: - Seed Data (first launch only)
    // =========================================================

    func seedIfNeeded() {
        // Only seed if arrays are empty
        guard categories.isEmpty else { return }

        // --- Categories ---
        let finance   = Category(name: "Finance",       sfSymbol: "dollarsign.circle")
        let identity  = Category(name: "Identity",      sfSymbol: "person.circle")
        let education = Category(name: "Education",     sfSymbol: "book.circle")
        let vehicle   = Category(name: "Vehicle",       sfSymbol: "car.side")
        let bills     = Category(name: "Service Bills", sfSymbol: "house")
        let policies  = Category(name: "Policies",      sfSymbol: "doc")
        let other     = Category(name: "Other",         sfSymbol: "questionmark.circle")

        categories = [finance, identity, education, vehicle, bills, policies, other]

        // --- User ---
        let seedUser = User(
            name: "Sanskaar Yadav",
            email: "abc@gmail.com",
            password: "xyz@123",
            phoneNumber: 964354627,
            dateOfBirth: Date(),
            gender: "Male"
        )
        _user = seedUser

        // --- Tags ---
        let tagData: [(String, String)] = [
            ("Red", "red"), ("Blue", "blue"), ("Green", "green"),
            ("Yellow", "yellow"), ("Purple", "purple"),
            ("Important", "red"), ("Work", "blue"), ("Personal", "green")
        ]
        tags = tagData.map { Tag(name: $0.0, color: $0.1) }

        // --- Documents ---
        documents = [
            Document(name: "Passport",
                     dueDate: Date().addingTimeInterval(86400 * 1),
                     isPinned: true,
                     userId: seedUser.id,
                     categoryId: identity.id,
                     assetName: "passport"),
            Document(name: "Electric Bill",
                     dueDate: Date().addingTimeInterval(86400 * 2),
                     isPinned: true,
                     userId: seedUser.id,
                     categoryId: bills.id,
                     assetName: "electric"),
            Document(name: "Water Bill",
                     dueDate: Date().addingTimeInterval(86400 * 3),
                     isPinned: true,
                     userId: seedUser.id,
                     categoryId: bills.id,
                     assetName: "waterBill"),
            Document(name: "Car Insurance",
                     dueDate: Date().addingTimeInterval(86400 * 30),
                     isPinned: true,
                     userId: seedUser.id,
                     categoryId: vehicle.id,
                     assetName: "Insurance"),
            Document(name: "Invoice for Induuction",
                     dueDate: Date().addingTimeInterval(86400 * 2),
                     isPinned: false,
                     userId: seedUser.id,
                     categoryId: finance.id,
                     assetName: "invoice"),
            Document(name: "Marksheet Class 12",
                     dueDate: nil,
                     isPinned: false,
                     userId: seedUser.id,
                     categoryId: education.id,
                     assetName: "marksheet"),
        ]

        // --- Unpaid Bills ---
        let unpaidBills = [
            Infetch(name: "Electricity Bill",
                    dueDate: Date().addingTimeInterval(86400 * 3),
                    billDate: Date().addingTimeInterval(-86400 * 27),
                    SubjectName: "BSES", amount: 1200,
                    customerName: "Rahul Sharma", phoneNumber: 9874125630,
                    billNumber: "BSES20260301", isPaid: false,
                    inFetchCatgogry: .bill),
            Infetch(name: "LIC Policy Premium",
                    dueDate: Date().addingTimeInterval(86400 * 10),
                    billDate: Date().addingTimeInterval(-86400 * 20),
                    SubjectName: "LIC", amount: 8000,
                    customerName: "Neelam Gupta", phoneNumber: 8127394056,
                    billNumber: "LIC20260315", isPaid: false,
                    inFetchCatgogry: .insurance),
            Infetch(name: "Credit Card Bill",
                    dueDate: Date().addingTimeInterval(86400 * 2),
                    billDate: Date().addingTimeInterval(-86400 * 28),
                    SubjectName: "HDFC", amount: 4700,
                    customerName: "Amit Verma", phoneNumber: 9456012738,
                    billNumber: "CC20260310", isPaid: false,
                    inFetchCatgogry: .finance),
            Infetch(name: "Home Loan EMI",
                    dueDate: Date().addingTimeInterval(86400 * 7),
                    billDate: Date().addingTimeInterval(-86400 * 25),
                    SubjectName: "SBI", amount: 12550,
                    customerName: "Vikas Singh", phoneNumber: 9038756214,
                    billNumber: "SBIHL202603", isPaid: false,
                    inFetchCatgogry: .finance),
            Infetch(name: "Netflix Subscription",
                    dueDate: Date().addingTimeInterval(86400 * 5),
                    billDate: Date().addingTimeInterval(-86400 * 25),
                    SubjectName: "Netflix", amount: 649,
                    customerName: "Priya Mehta", phoneNumber: 7682941503,
                    billNumber: "NFLX202603", isPaid: false,
                    inFetchCatgogry: .other),
            Infetch(name: "Car Insurance",
                    dueDate: Date().addingTimeInterval(86400 * 12),
                    billDate: Date().addingTimeInterval(-86400 * 18),
                    SubjectName: "ICICI Lombard", amount: 15000,
                    customerName: "Karan Patel", phoneNumber: 6297410853,
                    billNumber: "CARINS2026", isPaid: false,
                    inFetchCatgogry: .policy),
        ]

        // --- Paid Bills (History) ---
        let paidBills = [
            Infetch(name: "Water Bill",
                    dueDate: Date().addingTimeInterval(-86400 * 5),
                    billDate: Date().addingTimeInterval(-86400 * 35),
                    SubjectName: "DJB", amount: 430,
                    customerName: "Rahul Sharma", phoneNumber: nil,
                    billNumber: "DJB202602", isPaid: true,
                    inFetchCatgogry: .bill),
            Infetch(name: "Internet Bill",
                    dueDate: Date().addingTimeInterval(-86400 * 2),
                    billDate: Date().addingTimeInterval(-86400 * 32),
                    SubjectName: "Airtel", amount: 999,
                    customerName: "Rahul Sharma", phoneNumber: 7549823160,
                    billNumber: "AIR20260218", isPaid: true,
                    inFetchCatgogry: .bill),
            Infetch(name: "Health Insurance",
                    dueDate: Date().addingTimeInterval(-86400 * 60),
                    billDate: Date().addingTimeInterval(-86400 * 90),
                    SubjectName: "Star Health", amount: 18000,
                    customerName: "Neelam Gupta", phoneNumber: nil,
                    billNumber: "STARH20260101", isPaid: true,
                    inFetchCatgogry: .insurance),
        ]

        allBills = unpaidBills + paidBills
    }
}
