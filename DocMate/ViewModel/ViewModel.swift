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

    // MARK: - ModelContext (SwiftData)
    var modelContext: ModelContext?

    // MARK: - In-Memory Image Store (stays in memory for now)
    var imageStore: [UUID: [UIImage]] = [:]

    // MARK: - Gender Options
    var genderOptions: [String] = ["Male", "Female", "Other"]

    // MARK: - Max Pinned
    static let maxPinnedDocuments = 5

    // =========================================================
    // MARK: - Stored Data (populated from SwiftData)
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

    // MARK: - Unpaid Bills (computed from stored allBills)
    var inFetch: [Infetch] {
        allBills.filter { !$0.isPaid }
    }

    // MARK: - Paid Bills (computed from stored allBills)
    var billHistory: [Infetch] {
        allBills.filter { $0.isPaid }
    }

    // =========================================================
    // MARK: - Configure (call from view on appear)
    // =========================================================

    func configure(context: ModelContext) {
        guard self.modelContext == nil else { return }
        self.modelContext = context
        seedIfNeeded()
        fetchAll()
    }

    // =========================================================
    // MARK: - Fetch All (refreshes stored arrays from database)
    // =========================================================

    func fetchAll() {
        guard let modelContext else { return }

        let catDescriptor = FetchDescriptor<Category>(sortBy: [SortDescriptor(\.name)])
        categories = (try? modelContext.fetch(catDescriptor)) ?? []

        let docDescriptor = FetchDescriptor<Document>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        documents = (try? modelContext.fetch(docDescriptor)) ?? []

        let tagDescriptor = FetchDescriptor<Tag>()
        tags = (try? modelContext.fetch(tagDescriptor)) ?? []

        let billDescriptor = FetchDescriptor<Infetch>()
        allBills = (try? modelContext.fetch(billDescriptor)) ?? []

        let userDescriptor = FetchDescriptor<User>()
        _user = (try? modelContext.fetch(userDescriptor))?.first
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
        modelContext?.insert(document)
        try? modelContext?.save()
        if !images.isEmpty {
            imageStore[document.id] = images
        }
        fetchAll()
    }

    func deleteDocument(_ document: Document) {
        modelContext?.delete(document)
        try? modelContext?.save()
        fetchAll()
    }

    @discardableResult
    func togglePin(_ document: Document) -> Bool {
        if document.isPinned {
            document.isPinned = false
            try? modelContext?.save()
            fetchAll()
            return true
        } else {
            guard pinnedDocuments.count < AppViewModel.maxPinnedDocuments else { return false }
            document.isPinned = true
            try? modelContext?.save()
            fetchAll()
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

    func addScannedDocument(images: [UIImage], name: String, categoryId: UUID) {
        let doc = Document(
            name: name,
            isPinned: false,
            userId: user.id,
            categoryId: categoryId,
            fileType: .image
        )
        addDocument(doc, images: images)
    }

    func addPhotoDocument(image: UIImage, name: String, categoryId: UUID) {
        let doc = Document(
            name: name,
            isPinned: false,
            userId: user.id,
            categoryId: categoryId,
            fileType: .image
        )
        addDocument(doc, images: [image])
    }

    // =========================================================
    // MARK: - Category CRUD
    // =========================================================

    func addCategory(name: String, sfSymbol: String) {
        let cat = Category(name: name, sfSymbol: sfSymbol)
        modelContext?.insert(cat)
        try? modelContext?.save()
        fetchAll()
    }

    // =========================================================
    // MARK: - Bill Operations
    // =========================================================

    /// Simulates an API call. On success marks bill as paid.
    func refreshBill(_ bill: Infetch, completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let self else { return }
            let isPaid = Bool.random()

            if isPaid {
                bill.isPaid = true
                bill.dueDate = Date()
                try? self.modelContext?.save()
                self.fetchAll()
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
        guard let modelContext else { return }

        // Check if already seeded
        let catDescriptor = FetchDescriptor<Category>()
        let catCount = (try? modelContext.fetchCount(catDescriptor)) ?? 0
        guard catCount == 0 else { return }

        // --- Categories ---
        let finance   = Category(name: "Finance",       sfSymbol: "dollarsign.circle")
        let identity  = Category(name: "Identity",      sfSymbol: "person.circle")
        let education = Category(name: "Education",     sfSymbol: "book.circle")
        let vehicle   = Category(name: "Vehicle",       sfSymbol: "car.side")
        let bills     = Category(name: "Service Bills", sfSymbol: "house")
        let policies  = Category(name: "Policies",      sfSymbol: "doc")
        let other     = Category(name: "Other",         sfSymbol: "questionmark.circle")

        [finance, identity, education, vehicle, bills, policies, other].forEach {
            modelContext.insert($0)
        }

        // --- User ---
        let seedUser = User(
            name: "Sanskaar Yadav",
            email: "abc@gmail.com",
            password: "xyz@123",
            phoneNumber: 964354627,
            dateOfBirth: Date(),
            gender: "Male"
        )
        modelContext.insert(seedUser)

        // --- Tags ---
        let tagData: [(String, String)] = [
            ("Red", "red"), ("Blue", "blue"), ("Green", "green"),
            ("Yellow", "yellow"), ("Purple", "purple"),
            ("Important", "red"), ("Work", "blue"), ("Personal", "green")
        ]
        for (name, color) in tagData {
            modelContext.insert(Tag(name: name, color: color))
        }

        // --- Documents ---
        let seedDocs = [
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
        seedDocs.forEach { modelContext.insert($0) }

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
        unpaidBills.forEach { modelContext.insert($0) }

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
        paidBills.forEach { modelContext.insert($0) }

        // --- Save all ---
        try? modelContext.save()
    }
}
