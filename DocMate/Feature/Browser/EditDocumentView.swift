//
//  EditDocumentView.swift
//  DocMate
//
//  Created by Shashwat kumar on 27/04/26.
//



import SwiftUI

struct EditDocumentView: View {

    @Environment(AppViewModel.self) var viewModel
    @Environment(\.dismiss) var dismiss

    let document: Document

    @State private var name = ""
    @State private var selectedCategoryId = UUID()
    @State private var hasDueDate = false
    @State private var dueDate = Date()

    var body: some View {
        NavigationStack {
            Form {

                Section("Document Info") {

                    TextField("Document Name", text: $name)

                    NavigationLink {
                        BrowseView(
                            isSelecting: true,
                            selectedCategoryId: $selectedCategoryId
                        )
                    } label: {
                        HStack {
                            Text("Category")
                            Spacer()
                            Text(categoryName)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Expiry Date") {

                    Toggle("Has Expiry Date", isOn: $hasDueDate)

                    if hasDueDate {
                        DatePicker(
                            "Due Date",
                            selection: $dueDate,
                            displayedComponents: .date
                        )
                    }
                }
            }
            .navigationTitle("Edit Document")
            .navigationBarTitleDisplayMode(.inline)

            .toolbar {

                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveChanges()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            .onAppear {
                name = document.name
                selectedCategoryId = document.categoryId ?? UUID()

                if let due = document.dueDate {
                    hasDueDate = true
                    dueDate = due
                }
            }
        }
    }

    var categoryName: String {
        viewModel.categories.first {
            $0.id == selectedCategoryId
        }?.name ?? "Select"
    }

    @MainActor
    func saveChanges() async {

        var updated = document
        updated.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.categoryId = selectedCategoryId
        updated.dueDate = hasDueDate ? dueDate : nil

        do {
            try await SupabaseManager.shared.updateDocument(updated)
            await viewModel.fetchAll()
            dismiss()
        } catch {
            print("Edit document error:", error)
        }
    }
}
