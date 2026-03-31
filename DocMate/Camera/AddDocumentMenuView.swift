import SwiftUI

struct AddDocumentMenuView: View {
    var onScan: () -> Void
    var onImport: () -> Void

    var body: some View {
        VStack(spacing: 14) {

            // Drag indicator space is handled by presentationDragIndicator
            Text("Add Document")
                .font(.headline)
                .padding(.top, 4)

            VStack(spacing: 10) {
                MenuActionButton(
                    icon: "doc.viewfinder",
                    title: "Scan Document",
                    subtitle: "Use camera to scan",
                    action: onScan
                )

                MenuActionButton(
                    icon: "photo.on.rectangle.angled",
                    title: "Import Photo",
                    subtitle: "Pick from your library",
                    action: onImport
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

private struct MenuActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.blue)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(Color(.systemGray6))
            .cornerRadius(14)
        }
    }
}
