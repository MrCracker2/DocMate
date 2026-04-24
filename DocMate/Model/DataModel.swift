//
//  DataModel.swift
//  DocMateDummy
//
//  Created by Naman Yadav on 23/03/26.
//

import Foundation
import SwiftUI
import SwiftData

// MARK: - User
@Model
class User {
    var id: UUID = UUID()
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

    init(name: String, email: String, password: String, phoneNumber: Int, dateOfBirth: Date, gender: String) {
        self.name = name
        self.email = email
        self.password = password
        self.phoneNumber = phoneNumber
        self.dateOfBirth = dateOfBirth
        self.gender = gender
    }
}

// MARK: - Document
@Model
class Document {
    var id: UUID = UUID()
    var name: String
    var dueDate: Date?
    var isPinned: Bool
    var userId: UUID
    var categoryId: UUID
    var createdAt: Date
    var fileTypeRaw: String
    var assetName: String?
    var filePath: String?


    var fileType: DocumentFileType {
        get { DocumentFileType(rawValue: fileTypeRaw) ?? .image }
        set { fileTypeRaw = newValue.rawValue }
    }

    init(
        name: String,
        dueDate: Date? = nil,
        isPinned: Bool = false,
        userId: UUID,
        categoryId: UUID,
        createdAt: Date = Date(),
        fileType: DocumentFileType = .image,
        assetName: String? = nil,
        filePath: String? = nil
    ) {
        self.name = name
        self.dueDate = dueDate
        self.isPinned = isPinned
        self.userId = userId
        self.categoryId = categoryId
        self.createdAt = createdAt
        self.fileTypeRaw = fileType.rawValue
        self.assetName = assetName
        self.filePath = filePath       
    }
}

// Hashable conformance is provided automatically by @Model

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
@Model
class Category {
    var id: UUID = UUID()
    @Attribute(.unique) var name: String
    var sfSymbol: String

    init(name: String, sfSymbol: String) {
        self.name = name
        self.sfSymbol = sfSymbol
    }
}


// MARK: - Tag
@Model
class Tag {
    var id: UUID = UUID()
    @Attribute(.unique) var name: String
    var color: String

    init(name: String, color: String) {
        self.name = name
        self.color = color
    }
}


// MARK: - DocumentTag
//struct DocumentTag: Identifiable {
//    let id         = UUID()
//    var documentId : UUID
//    var tagId      : UUID
//}
@Model
class Infetch {
    var id: UUID = UUID()
    var name: String
    var dueDate: Date
    var billDate: Date
    var subjectName: String
    var amount: Double?
    var customerName: String
    var phoneNumber: Int?
    var billNumber: String
    var isPaid: Bool
    var infetchCategoryRaw: String

    var inFetchCatgogry: InfetchCategory {
        get { InfetchCategory(rawValue: infetchCategoryRaw) ?? .other }
        set { infetchCategoryRaw = newValue.rawValue }
    }

    init(
        name: String, dueDate: Date, billDate: Date,
        SubjectName: String, amount: Double?,
        customerName: String, phoneNumber: Int?,
        billNumber: String, isPaid: Bool,
        inFetchCatgogry: InfetchCategory
    ) {
        self.name = name
        self.dueDate = dueDate
        self.billDate = billDate
        self.subjectName = SubjectName
        self.amount = amount
        self.customerName = customerName
        self.phoneNumber = phoneNumber
        self.billNumber = billNumber
        self.isPaid = isPaid
        self.infetchCategoryRaw = inFetchCatgogry.rawValue
    }
}

enum InfetchCategory: String, CaseIterable, Identifiable {
    
    case bill = "Bill"
    case finance = "Finance"
    case insurance = "Insurance"
    case policy = "Policy"
    case other = "Other"

    var id: String { self.rawValue }
}
