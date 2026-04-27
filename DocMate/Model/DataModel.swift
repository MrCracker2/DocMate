//
//  DataModel.swift
//  DocMateDummy
//
//  Created by Naman Yadav on 23/03/26.
//

import Foundation
import SwiftUI

// MARK: - User (maps to `profiles` table in Supabase)
struct User: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var name: String
    var phone: Int?
    var dateOfBirth: String?
    var gender: String?

    var initials: String {
        let parts = name.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last  = parts.last?.prefix(1)  ?? ""
        return "\(first)\(last)".uppercased()
    }

    enum CodingKeys: String, CodingKey {
        case id, name, phone, gender
        case dateOfBirth = "date_of_birth"
    }

    init(
        id: UUID = UUID(),
        name: String = "",
        phone: Int? = nil,
        dateOfBirth: String? = nil,
        gender: String? = "Male"
    ) {
        self.id = id
        self.name = name
        self.phone = phone
        self.dateOfBirth = dateOfBirth
        self.gender = gender
    }
}

// MARK: - Document (maps to `documents` table in Supabase)
struct Document: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var userId: UUID
    var categoryId: UUID?
    var name: String
    var dueDate: Date?
    var isPinned: Bool
    var fileType: String
    var assetName: String?
    var filePath: String?
    var createdAt: Date

    var fileTypeEnum: DocumentFileType {
        get { DocumentFileType(rawValue: fileType) ?? .image }
        set { fileType = newValue.rawValue }
    }

    enum CodingKeys: String, CodingKey {
        case id, name
        case userId = "user_id"
        case categoryId = "category_id"
        case dueDate = "due_date"
        case isPinned = "is_pinned"
        case fileType = "file_type"
        case assetName = "asset_name"
        case filePath = "file_path"
        case createdAt = "created_at"
    }

    init(
        id: UUID = UUID(),
        name: String,
        dueDate: Date? = nil,
        isPinned: Bool = false,
        userId: UUID,
        categoryId: UUID? = nil,
        createdAt: Date = Date(),
        fileType: DocumentFileType = .image,
        assetName: String? = nil,
        filePath: String? = nil
    ) {
        self.id = id
        self.name = name
        self.dueDate = dueDate
        self.isPinned = isPinned
        self.userId = userId
        self.categoryId = categoryId
        self.createdAt = createdAt
        self.fileType = fileType.rawValue
        self.assetName = assetName
        self.filePath = filePath
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

// MARK: - Category (maps to `categories` table in Supabase)
struct Category: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var userId: UUID?
    var name: String
    var sfSymbol: String

    enum CodingKeys: String, CodingKey {
        case id, name
        case userId = "user_id"
        case sfSymbol = "sf_symbol"
    }

    init(id: UUID = UUID(), name: String, sfSymbol: String, userId: UUID? = nil) {
        self.id = id
        self.name = name
        self.sfSymbol = sfSymbol
        self.userId = userId
    }
}


// MARK: - Tag (maps to `tags` table in Supabase)
struct Tag: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var userId: UUID?
    var name: String
    var color: String

    enum CodingKeys: String, CodingKey {
        case id, name, color
        case userId = "user_id"
    }

    init(id: UUID = UUID(), name: String, color: String, userId: UUID? = nil) {
        self.id = id
        self.name = name
        self.color = color
        self.userId = userId
    }
}


// MARK: - Infetch / Bill (maps to `bills` table in Supabase)
struct Infetch: Identifiable, Hashable, Codable {

    var id: UUID = UUID()
    var userId: UUID?

    var name: String
    var dueDate: Date
    var billDate: Date
    var subjectName: String
    var amount: Double?

    var customerName: String
    var phoneNumber: Int?
    var billNumber: String

    var isPaid: Bool
    var gmailMessageId: String?
    var paidAt: Date?

    var category: String

    var inFetchCatgogry: InfetchCategory {
        get { InfetchCategory(rawValue: category) ?? .other }
        set { category = newValue.rawValue }
    }

    enum CodingKeys: String, CodingKey {
        case id, name, amount, category

        case userId = "user_id"
        case dueDate = "due_date"
        case billDate = "bill_date"
        case subjectName = "subject_name"
        case customerName = "customer_name"
        case phoneNumber = "phone_number"
        case billNumber = "bill_number"
        case isPaid = "is_paid"

        case gmailMessageId = "gmail_message_id"
        case paidAt = "paid_at"
    }

    init(
        id: UUID = UUID(),
        name: String,
        dueDate: Date,
        billDate: Date,
        SubjectName: String,
        amount: Double?,
        customerName: String,
        phoneNumber: Int?,
        billNumber: String,
        isPaid: Bool,
        gmailMessageId: String? = nil,
        paidAt: Date? = nil,
        inFetchCatgogry: InfetchCategory,
        userId: UUID? = nil
    ) {
        self.id = id
        self.name = name
        self.dueDate = dueDate
        self.billDate = billDate
        self.subjectName = SubjectName
        self.amount = amount
        self.customerName = customerName
        self.phoneNumber = phoneNumber
        self.billNumber = billNumber
        self.isPaid = isPaid
        self.gmailMessageId = gmailMessageId
        self.paidAt = paidAt
        self.category = inFetchCatgogry.rawValue
        self.userId = userId
    }
}
enum InfetchCategory: String, CaseIterable, Identifiable {

    case bill = "Bill"
    case finance = "Finance"
    case insurance = "Insurance"
    case policy = "Policy"
    case other = "Other"

    var id: String { rawValue }
}
