//
//  DataModel.swift
//  DocMateDummy
//
//  Created by Naman Yadav on 23/03/26.
//

import Foundation
import UIKit

@Observable
class AppViewModel {

    var imageStore: [UUID: [UIImage]] = [:]

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
            name: "Invoice",
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
        Tag(name: "Red", color: "red"),
        Tag(name: "Blue", color: "blue"),
        Tag(name: "Green", color: "green"),
        Tag(name: "Yellow", color: "yellow"),
        Tag(name: "Purple", color: "purple"),
        Tag(name: "Important", color: "red"),
        Tag(name: "Work", color: "blue"),
        Tag(name: "Personal", color: "green"),
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

    var inFetch: [Infetch] = [
        
        Infetch(
            name: "Electricity Bill",
            dueDate: Date().addingTimeInterval(86400 * 3),
            billDate: Date().addingTimeInterval(-86400 * 27),
            SubjectName: "BSES",
            amount: 1200,
            customerName: "Rahul Sharma",
            accountNumber: "ELEC123456",
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
            accountNumber: "LIC998877",
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
            accountNumber: "XXXX-1234",
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
            accountNumber: "HL009988",
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
            accountNumber: "NETFLIX-IND",
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
            accountNumber: "CAR998877",
            billNumber: "CARINS2026",
            isPaid: false,
            inFetchCatgogry: .policy
        )
    ]

    // MARK: - Computed
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

    // MARK: - Pin Limit
    static let maxPinnedDocuments = 5

    // unpin hamesha allow, pin sirf tab jab limit na bhari ho
    // Return value: false matlab limit full hai, caller alert dikhaye
    @discardableResult
    func togglePin(_ document: Document) -> Bool {
        guard let i = documents.firstIndex(where: { $0.id == document.id }) else { return false }

        if documents[i].isPinned {
            // Unpin — hamesha allow
            documents[i].isPinned = false
            return true
        } else {
            // Pin — pehle check karo limit
            guard pinnedDocuments.count < AppViewModel.maxPinnedDocuments else {
                return false  // limit full, caller ko bata do
            }
            documents[i].isPinned = true
            return true
        }
    }

    // MARK: - Browse Helpers
    func documents(for category: Category) -> [Document] {
        documents.filter { $0.categoryId == category.id }
    }

    func documentCount(for category: Category) -> Int {
        documents(for: category).count
    }

    // MARK: - Document Actions
    func images(for document: Document) -> [UIImage] {
        imageStore[document.id] ?? []
    }

    func deleteDocument(_ document: Document) {
        documents.removeAll { $0.id == document.id }
    }

    // MARK: - Category Actions
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
