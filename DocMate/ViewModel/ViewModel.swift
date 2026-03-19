//
//  ViewModel.swift
//  DocMate
//
//  Created by Shashwat kumar on 19/03/26.
//

import Foundation

@Observable
class AppViewModel {
    
    static let financeId   = UUID()
    static let identityId  = UUID()
    static let educationId = UUID()
    static let vehicleId   = UUID()
    static let billsId     = UUID()
    static let policiesId  = UUID()
    static let otherId     = UUID()

    var categories: [Category] = [
        Category(name: "Finance",       sfSymbol: "dollarsign.circle", fixedId: AppViewModel.financeId),
        Category(name: "Identity",      sfSymbol: "person.circle",     fixedId: AppViewModel.identityId),
        Category(name: "Education",     sfSymbol: "book.circle",       fixedId: AppViewModel.educationId),
        Category(name: "Vehicle",       sfSymbol: "car.side.fill",     fixedId: AppViewModel.vehicleId),
        Category(name: "Service Bills", sfSymbol: "house",             fixedId: AppViewModel.billsId),
        Category(name: "Policies",      sfSymbol: "doc",               fixedId: AppViewModel.policiesId),
        Category(name: "Other",         sfSymbol: "questionmark.circle", fixedId: AppViewModel.otherId)
    ]

    var documents: [Document] = [
        Document(name: "Passport",
                 dueDate: Date().addingTimeInterval(86400 * 1),
                 isPinned: true,
                 userId: UUID(),
                 categoryId: AppViewModel.identityId,
                 createdAt: Date(),
                 assetName: "passport"
                ),

        Document(name: "Electric Bill",
                 dueDate: Date().addingTimeInterval(86400 * 2),
                 isPinned: true,
                 userId: UUID(),
                 categoryId: AppViewModel.billsId,
                 createdAt: Date(),
                 assetName: "electric"
                ),

        Document(name: "Water Bill",
                 dueDate: Date().addingTimeInterval(86400 * 3),
                 isPinned: true,
                 userId: UUID(),
                 categoryId: AppViewModel.billsId,
                 createdAt: Date(),
                 assetName: "waterBill"
                ),

        Document(name: "Car Insurance",
                 dueDate: Date().addingTimeInterval(86400 * 30),
                 isPinned: true,
                 userId: UUID(),
                 categoryId: AppViewModel.vehicleId,
                 createdAt: Date(),
                 assetName: "Insurance"
                ),

        Document(name: "Invoice",
                 dueDate: Date().addingTimeInterval(86400 * 2),
                 isPinned: false,
                 userId: UUID(),
                 categoryId: AppViewModel.financeId,
                 createdAt: Date(),
                 assetName: "invoice"
                ),

        Document(name: "Marksheet Class 12",
                 dueDate: nil,
                 isPinned: false,
                 userId: UUID(),
                 categoryId: AppViewModel.educationId,
                 createdAt: Date(),
                 assetName: "marksheet"
                )
    ]

    var tags: [Tag] = [
        Tag(name: "Red",       color: "red"),
        Tag(name: "Blue",      color: "blue"),
        Tag(name: "Green",     color: "green"),
        Tag(name: "Yellow",    color: "yellow"),
        Tag(name: "Purple",    color: "purple"),
        Tag(name: "Important", color: "red"),
        Tag(name: "Work",      color: "blue"),
        Tag(name: "Personal",  color: "green")
    ]
    
    var documentTags:[DocumentTag] = []

    init() {
        
        documentTags = [
            DocumentTag(documentId: documents[0].id, tagId: tags[0].id),
            DocumentTag(documentId: documents[1].id, tagId: tags[1].id),
            DocumentTag(documentId: documents[2].id, tagId: tags[2].id),
            DocumentTag(documentId: documents[3].id, tagId: tags[5].id),
            DocumentTag(documentId: documents[4].id, tagId: tags[6].id),
            DocumentTag(documentId: documents[5].id, tagId: tags[7].id)
        ]
    }

    var user: User = User(
        name: "Sanskaar Yadav",
        email: "abc@gmail.com",
        password: "xyz@123",
        phoneNumber: 964354627,
        dateOfBirth: Date(),
        gender: "Male"
    )

    var genderOptions: [String] = ["Male", "Female", "Other"]

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

    // MARK: - Browse helpers
    func documents(for category: Category) -> [Document] {
        documents.filter { $0.categoryId == category.id }
    }
    func documentCount(for category: Category) -> Int {
        documents(for: category).count
    }

    // MARK: - Actions
    func togglePin(_ document: Document) {
        if let i = documents.firstIndex(where: { $0.id == document.id }) {
            documents[i].isPinned.toggle()
        }
    }
    
    func deleteDocument(_ document: Document) {
        documents.removeAll { $0.id == document.id }
    }
    func documents(for tag: Tag) -> [Document] {
        
        let docIds = documentTags
            .filter { $0.tagId == tag.id }
            .map { $0.documentId }
        
        return documents.filter { docIds.contains($0.id) }
    }
    
    var isGridView: Bool = true
}

