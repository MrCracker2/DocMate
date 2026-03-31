import SwiftUI

// MARK: - Category Icon Grid
struct CategoryIconGrid: View {
    let categories        : [Category]
    let viewModel         : AppViewModel
    @Binding var selectedCategoryId: UUID
    let onTapCategory     : (Category) -> Void

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 24) {
                ForEach(categories) { category in
                    Button { onTapCategory(category) } label: {
                        FilesStyleFolderTile(
                            name      : category.name,
                            sfSymbol  : category.sfSymbol,
                            itemCount : viewModel.documentCount(for: category),
                            isSelected: selectedCategoryId == category.id
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 20)
        }
    }
}

// MARK: - Category List View
struct CategoryListView: View {
    let categories        : [Category]
    let viewModel         : AppViewModel
    @Binding var selectedCategoryId: UUID
    let onTapCategory     : (Category) -> Void

    var body: some View {
        List {
            ForEach(categories) { category in
                Button { onTapCategory(category) } label: {
                    FilesStyleListRow(
                        name      : category.name,
                        sfSymbol  : category.sfSymbol,
                        detail    : "\(viewModel.documentCount(for: category)) items",
                        isSelected: selectedCategoryId == category.id
                    )
                }
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            }
        }
        .listStyle(.plain)
    }
}
