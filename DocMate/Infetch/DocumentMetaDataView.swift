import SwiftUI

struct DocumentMetaDataView: View {

    @Environment(AppViewModel.self) var appViewModel
    @Bindable var vm: InFetchViewModel

    @State private var fullscreenAsset: String? = nil

    // MARK: - Computed

    var allCategorized: Bool {
        vm.docMetaList.allSatisfy { $0.category != nil }
    }

    var categorizedCount: Int {
        vm.docMetaList.filter { $0.category != nil }.count
    }

    var progressValue: CGFloat {
        let total = vm.docMetaList.count
        return total == 0 ? 0 : CGFloat(categorizedCount) / CGFloat(total)
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {

            backgroundView

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach($vm.docMetaList) { $meta in
                        DocMetaCard(
                            meta: $meta,
                            categories: appViewModel.categories,
                            onPreviewTap: {
                                fullscreenAsset = meta.assetName
                            }
                        )
                        .padding(.horizontal, 16)
                    }
                    Spacer().frame(height: 110)
                }
                .padding(.top, 16)
            }

            bottomBar
        }
        .navigationTitle("Add Details")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar { toolbarView }
        .fullScreenCover(item: bindingAsset) { asset in
            LightboxView(assetName: asset.name)
        }
    }
}

// MARK: - Subviews

private extension DocumentMetaDataView {

    var backgroundView: some View {
        Color(.systemGroupedBackground).ignoresSafeArea()
    }

    var bottomBar: some View {
        VStack {
            Spacer()

            Button {
                vm.saveToMainModel(appViewModel: appViewModel)
                vm.reset()
                appViewModel.selectedTab = 0
            } label: {
                HStack {
                    Image(systemName: "checkmark")
                    Text("Save \(vm.docMetaList.count)")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(allCategorized ? Color.accentColor : Color(.systemFill))
                .foregroundStyle(allCategorized ? .white : Color(.tertiaryLabel))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
            }
            .disabled(!allCategorized)
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }
    var toolbarView: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                vm.fetchState = .results
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left").fontWeight(.semibold)
                    Text("Back")
                }
                .foregroundStyle(Color.accentColor)
            }
        }
    }

    var bindingAsset: Binding<NamedAsset?> {
        Binding(
            get: { fullscreenAsset.map { NamedAsset(name: $0) } },
            set: { fullscreenAsset = $0?.name }
        )
    }
}

// MARK: - Progress Bar

private struct ProgressBar: View {

    let progress: CGFloat
    let categorizedCount: Int
    let total: Int

    var body: some View {
        HStack(spacing: 10) {

            GeometryReader { geo in
                let width = geo.size.width
                let progressWidth = width * progress

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemFill))
                        .frame(height: 3)

                    Capsule()
                        .fill(Color.green)
                        .frame(width: progressWidth, height: 3)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 3)

            Text("\(categorizedCount) of \(total) categorised")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize()
        }
    }
}

// MARK: - Lightbox

private struct NamedAsset: Identifiable {
    var id: String { name }
    let name: String
}

private struct LightboxView: View {
    let assetName: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let uiImage = UIImage(named: assetName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .padding(16)
            }

            VStack {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white.opacity(0.85))
                            .padding()
                    }
                }
                Spacer()
            }
        }
    }
}

// MARK: - Card

private struct DocMetaCard: View {

    @Binding var meta: InFetchViewModel.DocMeta
    var categories: [Category]
    var onPreviewTap: () -> Void

    var body: some View {
        HStack(spacing: 0) {

            thumbnail

            Divider().frame(width: 0.5)

            details
        }
        .frame(height: 160)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Card Subviews

private extension DocMetaCard {

    var thumbnail: some View {
        ZStack {
            if let name = meta.assetName,
               let img = UIImage(named: name) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100)
                    .clipped()
                    .onTapGesture { onPreviewTap() }
            } else {
                Color(.secondarySystemFill)
                VStack(spacing: 6) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 22))
                        .foregroundStyle(.quaternary)
                    Text("No Preview")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.quaternary)
                }
            }
        }
        .frame(width: 100)
    }

    var details: some View {
        VStack(alignment: .leading, spacing: 0) {

            Text(meta.document.name)
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(2)
                .padding(12)

            Divider().padding(.leading, 12)

            categoryRow

            Divider().padding(.leading, 12)

            expiryRow
        }
    }

    var categoryRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Category")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                if let cat = meta.category {
                    Text(cat.name)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                } else {
                    Text("Not selected")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Menu {
                ForEach(categories) { cat in
                    Button {
                        meta.category = cat
                    } label: {
                        Label(cat.name, systemImage: cat.sfSymbol)
                    }
                }
            } label: {
                Text(meta.category == nil ? "Select" : "Change")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.accentColor)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 7))
            }
        }
        .padding(12)
    }

    var expiryRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Expiry")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                Text(meta.expiryDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption.weight(.semibold))
            }

            Spacer()

            DatePicker("", selection: $meta.expiryDate, displayedComponents: .date)
                .labelsHidden()
                .scaleEffect(0.85)
        }
        .padding(12)
    }
}
