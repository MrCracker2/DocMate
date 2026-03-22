//
//  InFetchViewModel.swift
//  DocMate
//
//  Created by Naman Yadav on 21/03/26.
//
import Foundation
import SwiftUI

@Observable
class InFetchViewModel {

    // MARK: - Fetch State Machine
    enum FetchState {
        case onboarding
        case loading
        case results
        case meta
    }

    var fetchState: FetchState = .onboarding

    // MARK: - Fetched Documents
    var fetchedDocs: [FetchedDocument] = []

    // MARK: - Selection
    var selectedIds: Set<UUID> = []

    // MARK: - Mapped Documents
    private(set) var mappedDocs: [Document] = []

    // MARK: - Selected Documents for MetaData screen
    var selectedDocuments: [Document] {
        mappedDocs.filter { selectedIds.contains($0.id) }
    }

    // MARK: - Per-Document Meta
    struct DocMeta: Identifiable {
        let id: UUID
        var document: Document
        var assetName: String?
        var category: Category?
        var expiryDate: Date
    }

    var docMetaList: [DocMeta] = []

    // MARK: - Mail Credentials
    var email: String = ""
    var password: String = ""

    // MARK: - Actions

    func startFetching() {
        fetchState = .loading
        fetchDocuments()
    }

    func toggleSelection(_ docId: UUID) {
        if selectedIds.contains(docId) {
            selectedIds.remove(docId)
        } else {
            selectedIds.insert(docId)
        }
    }

    func isSelected(_ docId: UUID) -> Bool {
        selectedIds.contains(docId)
    }

    func proceedToMeta(userId: UUID) {
        docMetaList = mappedDocs
            .filter { selectedIds.contains($0.id) }
            .compactMap { doc in
                let fetched = fetchedDocs.first { $0.name == doc.name }
                return DocMeta(
                    id: doc.id,
                    document: doc,
                    assetName: fetched?.assetName,
                    category: nil,
                    expiryDate: doc.dueDate ?? Date()
                )
            }
        fetchState = .meta
    }

    func saveToMainModel(appViewModel: AppViewModel) {
        for meta in docMetaList {
            guard let category = meta.category else { continue }

            let finalDoc = Document(
                name: meta.document.name,
                dueDate: meta.expiryDate,
                isPinned: false,
                userId: appViewModel.user.id,
                categoryId: category.id,
                createdAt: Date(),
                fileType: meta.document.fileType,
                assetName: meta.assetName
            )

            appViewModel.documents.append(finalDoc)
        }
    }

    func reset() {
        // .onboarding pe wapas — InFetchView khud decide karega dikhana kya hai
        fetchState = .onboarding
        fetchedDocs = []
        selectedIds = []
        mappedDocs = []
        docMetaList = []
    }

    // MARK: - Mock Fetch
    private func fetchDocuments() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self else { return }

            self.fetchedDocs = [
                FetchedDocument(
                    name: "Electricity Bill.pdf",
                    previewText: "BSES Rajdhani Power Ltd — Amount Due ₹1,240",
                    suggestedCategoryId: AppViewModel.billsId,
                    suggestedDate: Date().addingTimeInterval(86400 * 5),
                    assetName: "electric"
                ),
                FetchedDocument(
                    name: "Car Insurance.pdf",
                    previewText: "Bajaj Allianz — Policy valid till Dec 2026",
                    suggestedCategoryId: AppViewModel.vehicleId,
                    suggestedDate: Date().addingTimeInterval(86400 * 30),
                    assetName: "Insurance"
                ),
                FetchedDocument(
                    name: "Water Bill.pdf",
                    previewText: "Delhi Jal Board — Amount Due ₹540",
                    suggestedCategoryId: AppViewModel.billsId,
                    suggestedDate: Date().addingTimeInterval(86400 * 3),
                    assetName: "waterBill"
                ),
                FetchedDocument(
                    name: "Invoice.pdf",
                    previewText: "Amazon Order #408-XXXXXXX — ₹3,499",
                    suggestedCategoryId: AppViewModel.financeId,
                    suggestedDate: Date().addingTimeInterval(86400 * 2),
                    assetName: "invoice"
                )
            ]

            self.mappedDocs = self.fetchedDocs.map {
                DocumentMapper.map($0, userId: UUID())
            }

            self.fetchState = .results
        }
    }
}
