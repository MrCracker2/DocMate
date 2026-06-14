//
//  LocalDocument.swift
//  DocMate
//
//  Created by Antigravity on 14/06/26.
//

import Foundation
import SwiftData

@Model
final class LocalDocument {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var categoryId: UUID?
    var name: String
    var dueDate: Date?
    var isPinned: Bool
    var fileType: String
    var localFileName: String?
    var isSynced: Bool
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        categoryId: UUID? = nil,
        name: String,
        dueDate: Date? = nil,
        isPinned: Bool = false,
        fileType: String,
        localFileName: String? = nil,
        isSynced: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.categoryId = categoryId
        self.name = name
        self.dueDate = dueDate
        self.isPinned = isPinned
        self.fileType = fileType
        self.localFileName = localFileName
        self.isSynced = isSynced
        self.createdAt = createdAt
    }
}
