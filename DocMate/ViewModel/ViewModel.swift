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

    var documents: [Document] = [
        Document(name: "Passport", dueDate: Date().addingTimeInterval(86400 * 1),
                 isPinned: true, userId: UUID(), categoryId: AppViewModel.identityId,
                 createdAt: Date(), assetName: "passport"),

        Document(name: "Electric Bill", dueDate: Date().addingTimeInterval(86400 * 2),
                 isPinned: true, userId: UUID(), categoryId: AppViewModel.billsId,
                 createdAt: Date(), assetName: "electric"),

        Document(name: "Water Bill", dueDate: Date().addingTimeInterval(86400 * 3),
                 isPinned: true, userId: UUID(), categoryId: AppViewModel.billsId,
                 createdAt: Date(), assetName: "waterBill"),

        Document(name: "Car Insurance", dueDate: Date().addingTimeInterval(86400 * 30),
                 isPinned: true, userId: UUID(), categoryId: AppViewModel.vehicleId,
                 createdAt: Date(), assetName: "Insurance"),

        Document(name: "Invoice", dueDate: Date().addingTimeInterval(86400 * 2),
                 isPinned: false, userId: UUID(), categoryId: AppViewModel.financeId,
                 createdAt: Date(), assetName: "invoice"),

        Document(name: "Marksheet Class 12", dueDate: nil,
                 isPinned: false, userId: UUID(), categoryId: AppViewModel.educationId,
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
        Infetch(name: "Electricity Bill", dueDate: Date().addingTimeInterval(86400 * 3),
                SubjectName: "BSES", amount: 1200, inFetchCatgogry: .bill),

        Infetch(name: "Insurance Policy", dueDate: Date().addingTimeInterval(86400 * 10),
                SubjectName: "LIC", amount: nil, inFetchCatgogry: .insurance),

        Infetch(name: "Credit Card Bill", dueDate: Date().addingTimeInterval(86400 * 7),
                SubjectName: "LOAN", amount: 4700, inFetchCatgogry: .bill),

        Infetch(name: "Home Loan", dueDate: Date().addingTimeInterval(86400 * 7),
                SubjectName: "LOAN", amount: 12550, inFetchCatgogry: .bill),

        Infetch(name: "Netflix Bill", dueDate: Date().addingTimeInterval(86400 * 7),
                SubjectName: "Bill", amount: 2500, inFetchCatgogry: .bill),
    ]

    var selectedTab: Int = 0

    // MARK: - Computed
    var expiringDocuments: [Document] {
        documents.filter {
            guard let due = $0.dueDate else { return false } //Skip if no due is present
            return due < Date().addingTimeInterval(86400 * 10) //Show Documnets Expiring within 10 days
        }
    }

    //Start newiest first
    var recentDocuments: [Document] {
        documents.sorted { $0.createdAt > $1.createdAt }
    }

    
    //only pinned Documents
    var pinnedDocuments: [Document] {
        documents.filter { $0.isPinned }
    }

    // MARK: - Browse Helpers
    //Return only documents in that category
    func documents(for category: Category) -> [Document] {
        documents.filter { $0.categoryId == category.id }
    }

    //Return no of docs
    func documentCount(for category: Category) -> Int {
        documents(for: category).count
    }

    // MARK: - Document Actions
    //Add Documents
    func addDocument(_ document: Document, images: [UIImage] = []) {
        documents.append(document)
        if !images.isEmpty {
            imageStore[document.id] = images //save image if present
        }
    }

    //return images for a document
    func images(for document: Document) -> [UIImage] {
        imageStore[document.id] ?? []
    }
    func togglePin(_ document: Document) { //Switch true and false
        if let i = documents.firstIndex(where: { $0.id == document.id }) {
            documents[i].isPinned.toggle()
        }
    }

    //remove document
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
}
