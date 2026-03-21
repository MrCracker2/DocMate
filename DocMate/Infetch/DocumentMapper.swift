//
//  DocumentMapper.swift
//  DocMate
//
//  Created by Naman Yadav on 21/03/26.
//
import Foundation

struct DocumentMapper {

    /// FetchedDocument → main app Document
    /// Note: userId yahan placeholder hai — final save pe AppViewModel.user.id use hoga
    static func map(
        _ fetched: FetchedDocument,
        userId: UUID
    ) -> Document {
        return Document(
            name: fetched.name,
            dueDate: fetched.suggestedDate,
            isPinned: false,
            userId: userId,
            categoryId: fetched.suggestedCategoryId ?? UUID(),
            createdAt: Date(),
            fileType: .pdf,
            assetName: fetched.assetName       // image preview carry forward
        )
    }
}
