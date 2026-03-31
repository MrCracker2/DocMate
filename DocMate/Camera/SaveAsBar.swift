import SwiftUI

// MARK: - Save As Bar
struct SaveAsBar: View {
    let thumbnail: UIImage?
    @Binding var documentName: String
    @State private var isEditing = false

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                // Thumbnail
                Group {
                    if let thumb = thumbnail {
                        Image(uiImage: thumb)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Color(.systemGray5)
                            .overlay(
                                Image(systemName: "doc.fill")
                                    .foregroundStyle(.secondary)
                            )
                    }
                }
                .frame(width: 40, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color(.systemGray4), lineWidth: 0.5)
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Save as")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if isEditing {
                        TextField("Document name", text: $documentName)
                            .font(.body.weight(.medium))
                            .autocorrectionDisabled()
                            .submitLabel(.done)
                            .onSubmit { isEditing = false }
                    } else {
                        Text(documentName)
                            .font(.body.weight(.medium))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { isEditing.toggle() }
                } label: {
                    Image(systemName: isEditing ? "checkmark.circle.fill" : "pencil.circle")
                        .font(.title2)
                        .foregroundStyle(isEditing ? .blue : .secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.regularMaterial)
        }
    }
}
