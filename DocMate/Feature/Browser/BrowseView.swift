//
//  DocumentInfoView.swift
//  DocMate
//
//  Created by Naman Yadav on 27/04/26.
//
import SwiftUI

struct BrowseView: View {
    
    // MARK: - App Data
    @Environment(AppViewModel.self) var viewModel
    
    // MARK: - UI State
    @State private var searchText: String = ""
    @State private var isGridView: Bool = true
    @State private var showNewCategoryAlert = false
    @State private var categoryName = ""

    // MARK: - Category Context Menu State
    @State private var showRenameCategoryAlert = false
    @State private var renameCategoryText = ""
    @State private var categoryToRename: Category?
    @State private var showDeleteCategoryAlert = false
    @State private var categoryToDelete: Category?

    // MARK: - Selection Mode (IMPORTANT)
    let isSelecting: Bool
    @Binding var selectedCategoryId: UUID
    
    // MARK: - Init (default for normal browsing)
    init(
        isSelecting: Bool = false,
        selectedCategoryId: Binding<UUID> = .constant(UUID())
    ) {
        self.isSelecting = isSelecting
        self._selectedCategoryId = selectedCategoryId
    }
    
    // MARK: - Filter Logic
    var filteredCategories: [Category] {
        if searchText.isEmpty {
            return viewModel.categories
        }
        return viewModel.categories.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    //MARK: Gobal Serach
    var filteredDocuments: [Document] {
        guard !searchText.isEmpty else { return [] }
        
        return viewModel.documents.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    // MARK: Helper Function for filteredDocuments
    func categoryName(for doc: Document) -> String {
        viewModel.categories.first {
            $0.id == doc.categoryId
        }?.name ?? "Unknown"
    }
    
    // MARK: - Grid Layout
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    // MARK: - UI
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                
                // MARK: ===================== CATEGORIES =====================
                VStack(alignment: .leading, spacing: 12) {
                    
                    Text("Categories")
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    // MARK: GRID VIEW
                    if isGridView {
                        
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(filteredCategories) { category in
                                
                                //  CORE LOGIC: SWITCH BEHAVIOR BASED ON MODE
                                if isSelecting {
                                    
                                    //  SELECT MODE (NO NAVIGATION)
                                    Button {
                                        selectedCategoryId = category.id
                                    } label: {
                                        
                                        CategoryCardView(
                                            category: category,
                                            docCount: viewModel.documentCount(for: category)
                                        )
                                        //  Highlight selected category
                                        .background(
                                            selectedCategoryId == category.id
                                            ? Color.blue.opacity(0.15)
                                            : Color.clear
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(
                                                    selectedCategoryId == category.id
                                                    ? Color.blue
                                                    : Color.clear,
                                                    lineWidth: 2
                                                )
                                        )
                                        .cornerRadius(12)
                                    }
                                    .buttonStyle(.plain)
                                    
                                } else {
                                    
                                    //  NORMAL MODE (NAVIGATION)
                                    NavigationLink {
                                        CategoryDocumentsView(
                                            category: category,
                                            selectedCategoryId: $selectedCategoryId
                                        )
                                    } label: {
                                        CategoryCardView(
                                            category: category,
                                            docCount: viewModel.documentCount(for: category)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        categoryContextMenuItems(for: category)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // MARK: LIST VIEW
                    } else {
                        
                        VStack(spacing: 0) {
                            ForEach(filteredCategories) { category in
                                
                                if isSelecting {
                                    
                                    //  SELECT MODE (NO NAVIGATION)
                                    Button {
                                        selectedCategoryId = category.id
                                    } label: {
                                        
                                        HStack(spacing: 14) {
                                            
                                            // Icon
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.blue.opacity(0.12))
                                                    .frame(width: 40, height: 40)
                                                
                                                Image(systemName: category.sfSymbol)
                                                    .font(.system(size: 18))
                                                    .foregroundStyle(.blue)
                                            }
                                            
                                            // Name
                                            Text(category.name)
                                            
                                            Spacer()
                                            
                                            // Count
                                            Text("\(viewModel.documentCount(for: category))")
                                                .foregroundStyle(.secondary)
                                        }
                                        .padding(.vertical, 10)
                                        .padding(.horizontal)
                                        .background(
                                            selectedCategoryId == category.id
                                            ? Color.blue.opacity(0.15)
                                            : Color.clear
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    
                                } else {
                                    
                                    NavigationLink {
                                        CategoryDocumentsView(
                                            category: category,
                                            selectedCategoryId: $selectedCategoryId
                                        )
                                    } label: {
                                        
                                        HStack(spacing: 14) {
                                            
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.blue.opacity(0.12))
                                                    .frame(width: 40, height: 40)
                                                
                                                Image(systemName: category.sfSymbol)
                                                    .font(.system(size: 18))
                                                    .foregroundStyle(.blue)
                                            }
                                            
                                            Text(category.name)
                                            
                                            Spacer()
                                            
                                            Text("\(viewModel.documentCount(for: category))")
                                                .foregroundStyle(.secondary)
                                            
                                            Image(systemName: "chevron.right")
                                                .foregroundStyle(.tertiary)
                                        }
                                        .padding(.vertical, 10)
                                        .padding(.horizontal)
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        categoryContextMenuItems(for: category)
                                    }
                                }
                                
                                // Divider
                                if category.id != filteredCategories.last?.id {
                                    Divider()
                                        .padding(.leading, 68)
                                }
                            }
                        }
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                    }
                }
                
                if !searchText.isEmpty && !filteredDocuments.isEmpty {
                    
                    VStack(alignment: .leading, spacing: 12) {
                        
                        Text("Documents")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            
                            ForEach(filteredDocuments) { doc in
                                
                                NavigationLink {
                                    DocumentDetailView(document: doc)
                                } label: {
                                    
                                    HStack(spacing: 12) {
                                        
                                        Image(systemName: doc.fileTypeEnum.sfSymbol)
                                            .frame(width: 24)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(doc.name)
                                            
                                            Text(categoryName(for: doc))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(.tertiary)
                                    }
                                    .padding()
                                }
                                
                                if doc.id != filteredDocuments.last?.id {
                                    Divider()
                                }
                            }
                        }
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                    }
                }
                
                // MARK: ===================== TAGS =====================
                if searchText.isEmpty {
                    
                    VStack(alignment: .leading, spacing: 12) {
                        
                        Text("Tags")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            ForEach(viewModel.tags) { tag in
                                TagRowView(tag: tag)
                                
                                if tag.id != viewModel.tags.last?.id {
                                    Divider()
                                        .padding(.leading)
                                }
                            }
                        }
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                    }
                }            }
            .padding(.top, 8)
            .padding(.bottom, 30)
        }
        
        // MARK: ===================== NAVIGATION =====================
        .navigationTitle("Browse")
        .navigationBarTitleDisplayMode(
            isSelecting ? .inline : .large
        )
        
        // MARK: Search
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search documents or categories"
        )
        
        // MARK: Toolbar
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {

                    Button {
                        showNewCategoryAlert = true
                    } label: {
                        Label("New Category", systemImage: "folder.badge.plus")
                    }
                    
                    Divider()
                    
                    Button {
                        isGridView = true
                    } label: {
                        Label("Icons", systemImage: "square.grid.2x2")
                    }
                    
                    Button {
                        isGridView = false
                    } label: {
                        Label("List", systemImage: "list.bullet")
                    }
                    
                    Divider()
                    
                    Button {} label: { Label("Name", systemImage: "textformat") }
                    Button {} label: { Label("Kind", systemImage: "doc") }
                    Button {} label: { Label("Date", systemImage: "calendar") }
                    Button {} label: { Label("Size", systemImage: "arrow.up.and.down") }
                    
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.title3)
                }
            }
        }
        .alert("New Category", isPresented: $showNewCategoryAlert) {

            TextField("Category Name", text: $categoryName)

            Button("Create") {
                guard !categoryName.isEmpty else { return }

                Task {
                    await viewModel.addCategory(
                        name: categoryName,
                        sfSymbol: "folder.fill"
                    )

                    categoryName = ""
                }
            }
            Button("Cancel", role: .cancel) {
                categoryName = ""
            }
        }

        // MARK: - Rename Category Alert
        .alert("Rename Category", isPresented: $showRenameCategoryAlert) {
            TextField("Category name", text: $renameCategoryText)
                .autocorrectionDisabled()
            Button("Rename") {
                if let cat = categoryToRename, !renameCategoryText.isEmpty {
                    Task {
                        await viewModel.renameCategory(cat, to: renameCategoryText)
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        }

        // MARK: - Delete Category Confirmation
        .alert("Delete Category", isPresented: $showDeleteCategoryAlert) {
            Button("Delete", role: .destructive) {
                if let cat = categoryToDelete {
                    Task {
                        await viewModel.deleteCategory(cat)
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            if let cat = categoryToDelete {
                Text("Are you sure you want to delete \"\(cat.name)\"? All documents inside will also be deleted.")
            }
        }
    }

    // MARK: - Category Context Menu
    @ViewBuilder
    func categoryContextMenuItems(for category: Category) -> some View {
        Button {
            categoryToRename = category
            renameCategoryText = category.name
            showRenameCategoryAlert = true
        } label: {
            Label("Rename", systemImage: "pencil")
        }

        Button(role: .destructive) {
            categoryToDelete = category
            showDeleteCategoryAlert = true
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
}
