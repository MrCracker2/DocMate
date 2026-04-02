//
//  DataModel.swift
//  DocMateDummy
//
//  Created by Naman Yadav on 23/03/26.
//

import Foundation

// MARK: - User
struct User: Identifiable {
    let id = UUID()
    var name: String
    var email: String
    var password: String
    var phoneNumber: Int
    var dateOfBirth: Date
    var gender: String

    var initials: String {
        let parts = name.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last  = parts.last?.prefix(1)  ?? ""
        return "\(first)\(last)".uppercased()
    }
}

// MARK: - Document
struct Document: Identifiable {
    let id         : UUID
    var name       : String
    var dueDate    : Date?
    var isPinned   : Bool
    var userId     : UUID
    var categoryId : UUID
    var createdAt  : Date
    var fileType   : DocumentFileType
    var assetName  : String?

    init(
        name       : String,
        dueDate    : Date?            = nil,
        isPinned   : Bool             = false,
        userId     : UUID,
        categoryId : UUID,
        createdAt  : Date             = Date(),
        fileType   : DocumentFileType = .image,
        assetName  : String?          = nil
    ) {
        self.id         = UUID()
        self.name       = name
        self.dueDate    = dueDate
        self.isPinned   = isPinned
        self.userId     = userId
        self.categoryId = categoryId
        self.createdAt  = createdAt
        self.fileType   = fileType
        self.assetName  = assetName
    }
}

extension Document: Hashable {
    static func == (lhs: Document, rhs: Document) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Document File Type
enum DocumentFileType: String, Codable, Hashable {
    case image
    case pdf

    var sfSymbol: String {              // computed property it depended on file type ,no need to store it
        switch self {
        case .image: return "photo.fill"
        case .pdf:   return "doc.fill"
        }
    }
}

// MARK: - Category
struct Category: Identifiable, Hashable {
    let id      : UUID
    var name    : String
    var sfSymbol: String

    init(name: String, sfSymbol: String) {
        self.id       = UUID()
        self.name     = name
        self.sfSymbol = sfSymbol
    }

    init(name: String, sfSymbol: String, fixedId: UUID) {
        self.id       = fixedId
        self.name     = name
        self.sfSymbol = sfSymbol
    }
}

// MARK: - Tag
struct Tag: Identifiable, Hashable {
    let id    = UUID()
    var name  : String
    var color : String
}

// MARK: - DocumentTag
struct DocumentTag: Identifiable {
    let id         = UUID()
    var documentId : UUID
    var tagId      : UUID
}
struct Infetch:Identifiable{
    let id=UUID()
    var name:String
    var dueDate:Date
    var SubjectName:String
    var amount:Double?
    var inFetchCatgogry:InfetchCategory
}
enum InfetchCategory: String, CaseIterable, Identifiable {
    
    case bill = "Bill"
    case finance = "Finance"
    case insurance = "Insurance"
    case policy = "Policy"
    case other = "Other"

    var id: String { self.rawValue }
}
