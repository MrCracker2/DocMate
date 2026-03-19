//
//  DataModel.swift
//  DocMate
//
//  Created by Shashwat kumar on 19/03/26.
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

struct Document: Identifiable, Hashable {
    let id         : UUID
    var name       : String
    var dueDate    : Date?
    var isPinned   : Bool
    var userId     : UUID
    var categoryId : UUID
    var createdAt  : Date
    var fileType   : DocumentFileType
    var fileName   : String?
    var assetName: String?

    init(name: String,
         dueDate: Date? = nil,
         isPinned: Bool = false,
         userId: UUID,
         categoryId: UUID,
         createdAt: Date = Date(),
         fileType: DocumentFileType = .pdf,
         fileName: String? = nil,
         assetName: String? = nil
    ) {
        self.id         = UUID()
        self.name       = name
        self.dueDate    = dueDate
        self.isPinned   = isPinned
        self.userId     = userId
        self.categoryId = categoryId
        self.createdAt  = createdAt
        self.fileType   = fileType
        self.fileName   = fileName
        self.assetName  = assetName
    }
}

// MARK: - Document File Type
enum DocumentFileType: String, Codable, Hashable {
    case image
    case pdf

    var sfSymbol: String {
        switch self {
        case .image: return "photo.fill"
        case .pdf:   return "doc.fill"
        }
    }
}

// MARK: - Category  (Hashable for Picker)
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
