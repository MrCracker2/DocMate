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
        Document(name: "Passport",         dueDate: Date().addingTimeInterval(86400 * 1),  isPinned: true,  userId: UUID(), categoryId: AppViewModel.identityId,  createdAt: Date(), assetName: "passport"),
        Document(name: "Electric Bill",    dueDate: Date().addingTimeInterval(86400 * 2),  isPinned: true,  userId: UUID(), categoryId: AppViewModel.billsId,     createdAt: Date(), assetName: "electric"),
        Document(name: "Water Bill",       dueDate: Date().addingTimeInterval(86400 * 3),  isPinned: true,  userId: UUID(), categoryId: AppViewModel.billsId,     createdAt: Date(), assetName: "waterBill"),
        Document(name: "Car Insurance",    dueDate: Date().addingTimeInterval(86400 * 30), isPinned: true,  userId: UUID(), categoryId: AppViewModel.vehicleId,   createdAt: Date(), assetName: "Insurance"),
        Document(name: "Invoice",          dueDate: Date().addingTimeInterval(86400 * 2),  isPinned: false, userId: UUID(), categoryId: AppViewModel.financeId,   createdAt: Date(), assetName: "invoice"),
        Document(name: "Marksheet Class 12", dueDate: nil,                                 isPinned: false, userId: UUID(), categoryId: AppViewModel.educationId, createdAt: Date(), assetName: "marksheet"),
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
        name: "Sanskaar Yadav", email: "abc@gmail.com",
        password: "xyz@123", phoneNumber: 964354627,
        dateOfBirth: Date(), gender: "Male"
    )

    var genderOptions: [String] = ["Male", "Female", "Other"]

    var inFetch: [Infetch] = [
        Infetch(name: "Electricity Bill",  dueDate: Date().addingTimeInterval(86400 * 3),  subjectName: "BSES", amount: 1200,  inFetchCategory: .bill),
        Infetch(name: "Insurance Policy",  dueDate: Date().addingTimeInterval(86400 * 10), subjectName: "LIC",  amount: nil,   inFetchCategory: .insurance),
        Infetch(name: "Credit Card Bill",  dueDate: Date().addingTimeInterval(86400 * 7),  subjectName: "LOAN", amount: 4700,  inFetchCategory: .bill),
        Infetch(name: "Home Loan",         dueDate: Date().addingTimeInterval(86400 * 7),  subjectName: "LOAN", amount: 12550, inFetchCategory: .bill),
        Infetch(name: "Netflix Bill",      dueDate: Date().addingTimeInterval(86400 * 7),  subjectName: "Bill", amount: 2500,  inFetchCategory: .bill),
    ]

    var selectedTab: Int = 0

    // MARK: - Computed
    var expiringDocuments: [Document] {
        documents.filter {
            guard let due = $0.dueDate else { return false }
            return due < Date().addingTimeInterval(86400 * 10)
        }
    }
    var recentDocuments : [Document] { documents.sorted { $0.createdAt > $1.createdAt } }
    var pinnedDocuments : [Document] { documents.filter { $0.isPinned } }

    // MARK: - Browse Helpers
    func documents(for category: Category) -> [Document] {
        documents.filter { $0.categoryId == category.id }
    }
    func documentCount(for category: Category) -> Int {
        documents(for: category).count
    }

    // MARK: - Document Actions
    func addDocument(_ document: Document, images: [UIImage] = []) {
        documents.append(document)
        if !images.isEmpty { imageStore[document.id] = images }
    }
    func images(for document: Document) -> [UIImage] { imageStore[document.id] ?? [] }
    func togglePin(_ document: Document) {
        if let i = documents.firstIndex(where: { $0.id == document.id }) {
            documents[i].isPinned.toggle()
        }
    }
    func deleteDocument(_ document: Document) {
        documents.removeAll { $0.id == document.id }
    }

    // MARK: - Category Actions
    func addCategory(name: String, sfSymbol: String) {      //  now correctly outside deleteDocument
        categories.append(Category(name: name, sfSymbol: sfSymbol))
    }

    // MARK: - InFetch
    func importInfetchToDocuments() {
        for doc in inFetch {
            let newDoc = Document(name: doc.name, dueDate: doc.dueDate, isPinned: false,
                                  userId: user.id, categoryId: mapCategory(doc.inFetchCategory), fileType: .pdf)
            documents.append(newDoc)
        }
        inFetch.removeAll()
    }
    func mapCategory(_ cat: InfetchCategory) -> UUID {
        switch cat {
        case .bill:              return AppViewModel.billsId
        case .insurance, .policy: return AppViewModel.policiesId
        case .finance:           return AppViewModel.financeId
        default:                 return AppViewModel.otherId
        }
    }

    // MARK: - Scanner & Photo
    func addScannedDocument(images: [UIImage], name: String, categoryId: UUID, subCategoryId: UUID? = nil) {
        guard let pdfData = PDFService.createPDF(from: images),
              let url = DocumentManager.shared.savePDF(data: pdfData) else { return }
        addDocument(Document(name: name, isPinned: false, userId: user.id, categoryId: categoryId,
                             fileType: .pdf, fileURL: url), images: images)
    }
    func addPhotoDocument(image: UIImage, name: String, categoryId: UUID, subCategoryId: UUID? = nil) {
        guard let pdfData = PDFService.createPDF(from: [image]),
              let url = DocumentManager.shared.savePDF(data: pdfData) else { return }
        addDocument(Document(name: name, isPinned: false, userId: user.id, categoryId: categoryId,
                             fileType: .pdf, fileURL: url), images: [image])
    }
}

// MARK: - PDF Service
struct PDFService {
    static func createPDF(from images: [UIImage]) -> Data? {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595, height: 842))
        return renderer.pdfData { context in
            for image in images {
                context.beginPage()
                image.draw(in: CGRect(x: 0, y: 0, width: 595, height: 842))
            }
        }
    }
}

// MARK: - Document Manager
final class DocumentManager {
    static let shared = DocumentManager()
    private init() {}

    func savePDF(data: Data) -> URL? {
        let url = getDocumentsDirectory().appendingPathComponent("Doc-\(UUID().uuidString.prefix(6)).pdf")
        do { try data.write(to: url); return url }
        catch { print("Error saving PDF:", error); return nil }
    }
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
