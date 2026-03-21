//
//  InFetchDataModel.swift
//  DocMate
//
//  Created by Naman Yadav on 20/03/26.
//
import Foundation

struct FetchedDocument: Identifiable, Hashable {

    let id = UUID()

    // MARK: - Basic Info (from email)
    var name: String
    var previewText: String?

    // MARK: - Suggested Data (auto-detected)
    var suggestedCategoryId: UUID?
    var suggestedDate: Date?

    // MARK: - Preview Image
    // Asset catalog ka naam — abhi ke liye mock data mein hardcode hai,
    // real implementation mein email attachment thumbnail yahan aayega
    var assetName: String?

    // MARK: - UI State
    var isSelected: Bool = false
}
