//
//  DataModel.swift
//  DocMateDummy
//
//  Created by Naman Yadav on 23/03/26.
//
//

import Foundation
import UIKit

@Observable
class AppViewModel {

    var imageStore: [UUID: [UIImage]] = [:]

    // MARK: - Category Fixed IDs
    static let financeId   = UUID()
    static let identityId  = UUID()
    static let educationId = UUID()
    static let vehicleId   = UUID()
    static let billsId     = UUID()
    static let policiesId  = UUID()
    static let otherId     = UUID()

    var categories: [Category] = [
        Category(name: "Finance",       sfSymbol: "dollarsign.circle",   fixedId: AppViewModel.financeId),
        Category(name: "Identity",      sfSymbol: "person.circle",       fixedId: AppViewModel.identityId),
        Category(name: "Education",     sfSymbol: "book.circle",         fixedId: AppViewModel.educationId),
        Category(name: "Vehicle",       sfSymbol: "car.side",            fixedId: AppViewModel.vehicleId),
        Category(name: "Service Bills", sfSymbol: "house",               fixedId: AppViewModel.billsId),
        Category(name: "Policies",      sfSymbol: "doc",                 fixedId: AppViewModel.policiesId),
        Category(name: "Other",         sfSymbol: "questionmark.circle", fixedId: AppViewModel.otherId),
    ]

    func icon(for document: Document) -> String {
        categories.first(where: { $0.id == document.categoryId })?.sfSymbol ?? "doc.text"
    }

    // MARK: - Documents
    var documents: [Document] = [
        Document(
            name: "Passport",
            dueDate: Date().addingTimeInterval(86400 * 1),
            isPinned: true,
            userId: UUID(),
            categoryId: AppViewModel.identityId,
            createdAt: Date(),
            assetName: "passport"),
        Document(
            name: "Electric Bill",
            dueDate: Date().addingTimeInterval(86400 * 2),
            isPinned: true,
            userId: UUID(),
            categoryId: AppViewModel.billsId,
            createdAt: Date(), assetName: "electric"),
        Document(
            name: "Water Bill",
            dueDate: Date().addingTimeInterval(86400 * 3),
            isPinned: true,
            userId: UUID(),
            categoryId: AppViewModel.billsId,
            createdAt: Date(), assetName: "waterBill"),
        Document(
            name: "Car Insurance",
            dueDate: Date().addingTimeInterval(86400 * 30),
            isPinned: true,
            userId: UUID(),
            categoryId: AppViewModel.vehicleId,
            createdAt: Date(), assetName: "Insurance"),
        Document(
            name: "Invoice for Induuction",
            dueDate: Date().addingTimeInterval(86400 * 2),
            isPinned: false,
            userId: UUID(),
            categoryId: AppViewModel.financeId,
            createdAt: Date(), assetName: "invoice"),
        Document(
            name: "Marksheet Class 12",
            dueDate: nil,
            isPinned: false,
            userId: UUID(),
            categoryId: AppViewModel.educationId,
            createdAt: Date(), assetName: "marksheet"),
    ]

    var tags: [Tag] = [
        Tag(name: "Red",       color: "red"),
        Tag(name: "Blue",      color: "blue"),
        Tag(name: "Green",     color: "green"),
        Tag(name: "Yellow",    color: "yellow"),
        Tag(name: "Purple",    color: "purple"),
        Tag(name: "Important", color: "red"),
        Tag(name: "Work",      color: "blue"),
        Tag(name: "Personal",  color: "green"),
    ]

    var user: User = User(
        name: "Sanskaar Yadav",
        email: "abc@gmail.com",
        password: "xyz@123",
        phoneNumber: 964354627,
        dateOfBirth: Date(),
        gender: "Male"
    )

    var genderOptions: [String] = ["Male", "Female", "Other"]

    // MARK: - Unpaid Bills
    var inFetch: [Infetch] = [
        Infetch(
            name: "Electricity Bill",
            dueDate: Date().addingTimeInterval(86400 * 3),
            billDate: Date().addingTimeInterval(-86400 * 27),
            SubjectName: "BSES",
            amount: 1200,
            customerName: "Rahul Sharma",
            phoneNumber: 9874125630,
            billNumber: "BSES20260301",
            isPaid: false,
            inFetchCatgogry: .bill
        ),
        Infetch(
            name: "LIC Policy Premium",
            dueDate: Date().addingTimeInterval(86400 * 10),
            billDate: Date().addingTimeInterval(-86400 * 20),
            SubjectName: "LIC",
            amount: 8000,
            customerName: "Neelam Gupta",
            phoneNumber: 8127394056,
            billNumber: "LIC20260315",
            isPaid: false,
            inFetchCatgogry: .insurance
        ),
        Infetch(
            name: "Credit Card Bill",
            dueDate: Date().addingTimeInterval(86400 * 2),
            billDate: Date().addingTimeInterval(-86400 * 28),
            SubjectName: "HDFC",
            amount: 4700,
            customerName: "Amit Verma",
            phoneNumber: 9456012738,
            billNumber: "CC20260310",
            isPaid: false,
            inFetchCatgogry: .finance
        ),
        Infetch(
            name: "Home Loan EMI",
            dueDate: Date().addingTimeInterval(86400 * 7),
            billDate: Date().addingTimeInterval(-86400 * 25),
            SubjectName: "SBI",
            amount: 12550,
            customerName: "Vikas Singh",
            phoneNumber: 9038756214,
            billNumber: "SBIHL202603",
            isPaid: false,
            inFetchCatgogry: .finance
        ),
        Infetch(
            name: "Netflix Subscription",
            dueDate: Date().addingTimeInterval(86400 * 5),
            billDate: Date().addingTimeInterval(-86400 * 25),
            SubjectName: "Netflix",
            amount: 649,
            customerName: "Priya Mehta",
            phoneNumber: 7682941503,
            billNumber: "NFLX202603",
            isPaid: false,
            inFetchCatgogry: .other
        ),
        Infetch(
            name: "Car Insurance",
            dueDate: Date().addingTimeInterval(86400 * 12),
            billDate: Date().addingTimeInterval(-86400 * 18),
            SubjectName: "ICICI Lombard",
            amount: 15000,
            customerName: "Karan Patel",
            phoneNumber: 6297410853,
            billNumber: "CARINS2026",
            isPaid: false,
            inFetchCatgogry: .policy
        )
    ]

    // MARK: - ✅ Paid Bills History (NEW)
    var billHistory: [Infetch] = [
        // Pre-seeded history so the history screen is populated on first launch
        Infetch(
            name: "Water Bill",
            dueDate: Date().addingTimeInterval(-86400 * 5),
            billDate: Date().addingTimeInterval(-86400 * 35),
            SubjectName: "DJB",
            amount: 430,
            customerName: "Rahul Sharma",
            phoneNumber: nil ,
            billNumber: "DJB202602",
            isPaid: true,
            inFetchCatgogry: .bill
        ),
        Infetch(
            name: "Internet Bill",
            dueDate: Date().addingTimeInterval(-86400 * 2),
            billDate: Date().addingTimeInterval(-86400 * 32),
            SubjectName: "Airtel",
            amount: 999,
            customerName: "Rahul Sharma",
            phoneNumber: 7549823160,
            billNumber: "AIR20260218",
            isPaid: true,
            inFetchCatgogry: .bill
        ),
        Infetch(
            name: "Health Insurance",
            dueDate: Date().addingTimeInterval(-86400 * 60),
            billDate: Date().addingTimeInterval(-86400 * 90),
            SubjectName: "Star Health",
            amount: 18000,
            customerName: "Neelam Gupta",
            phoneNumber:  nil ,
            billNumber: "STARH20260101",
            isPaid: true,
            inFetchCatgogry: .insurance
        ),
    ]

    // MARK: - ✅ Refresh / Simulate Payment (NEW)
    /// Simulates an API call. On success (Bool.random()), marks bill as paid
    /// and moves it from `inFetch` → `billHistory`.
    /// Animation is intentionally absent here — the call site (View) wraps
    /// the completion in `withAnimation` so SwiftUI can drive it correctly.
    func refreshBill(_ bill: Infetch, completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let self else { return }
            let isPaid = Bool.random()

            if isPaid {
                var paidBill = bill
                paidBill.isPaid = true
                paidBill.dueDate = Date()   // anchor to today in history

                self.inFetch.removeAll { $0.id == bill.id }
                self.billHistory.insert(paidBill, at: 0)
            }
            completion(isPaid)
        }
    }

    // MARK: - ✅ Total Spend Helper (NEW)
    /// Returns total amount paid within the given month filter.
    func totalSpend(for filter: BillMonthFilter) -> Double {
        billsFiltered(by: filter)
            .compactMap { $0.amount }
            .reduce(0, +)
    }

    // MARK: - ✅ Filter Helper (NEW)
    func billsFiltered(by filter: BillMonthFilter) -> [Infetch] {
        let calendar = Calendar.current
        let reference = filter.referenceDate
        return billHistory.filter { bill in
            calendar.isDate(bill.dueDate, equalTo: reference, toGranularity: .month)
        }
    }

    // MARK: - Computed (unchanged)
    var expiringDocuments: [Document] {
        documents.filter {
            guard let due = $0.dueDate else { return false }
            return due < Date().addingTimeInterval(86400 * 10)
        }
    }

    var recentDocuments: [Document] {
        documents.sorted { $0.createdAt > $1.createdAt }
    }

    var pinnedDocuments: [Document] {
        documents.filter { $0.isPinned }
    }

    static let maxPinnedDocuments = 5

    @discardableResult
    func togglePin(_ document: Document) -> Bool {
        guard let i = documents.firstIndex(where: { $0.id == document.id }) else { return false }
        if documents[i].isPinned {
            documents[i].isPinned = false
            return true
        } else {
            guard pinnedDocuments.count < AppViewModel.maxPinnedDocuments else { return false }
            documents[i].isPinned = true
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

    func deleteDocument(_ document: Document) {
        documents.removeAll { $0.id == document.id }
    }

    func addCategory(name: String, sfSymbol: String) {
        categories.append(Category(name: name, sfSymbol: sfSymbol))
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

    func addDocument(_ document: Document, images: [UIImage] = []) {
        documents.append(document)
        if !images.isEmpty {
            imageStore[document.id] = images
        }
    }
}
