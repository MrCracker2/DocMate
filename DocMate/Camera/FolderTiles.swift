import SwiftUI

// MARK: - Files-style Folder Tile (Icons view)
struct FilesStyleFolderTile: View {
    let name      : String
    let sfSymbol  : String
    let itemCount : Int
    let isSelected: Bool

    private let filesBlue = Color(red: 0.36, green: 0.68, blue: 0.93)

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Image(systemName: "folder.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 76, height: 62)
                    .foregroundStyle(filesBlue)
                Image(systemName: sfSymbol)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
                    .offset(y: 5)
            }
            Text(name)
                .font(.caption)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundStyle(.primary)
            Text("\(itemCount) \(itemCount == 1 ? "item" : "items")")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(isSelected ? filesBlue.opacity(0.15) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? filesBlue.opacity(0.6) : Color.clear, lineWidth: 1.5)
        )
    }
}

// MARK: - Files-style List Row (List view)
struct FilesStyleListRow: View {
    let name      : String
    let sfSymbol  : String
    let detail    : String
    let isSelected: Bool

    private let filesBlue = Color(red: 0.36, green: 0.68, blue: 0.93)

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Image(systemName: "folder.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 36)
                    .foregroundStyle(filesBlue)
                Image(systemName: sfSymbol)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white)
                    .offset(y: 3)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.body).foregroundStyle(.primary)
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(.blue)
                    .fontWeight(.semibold)
            }
            Image(systemName: "chevron.right")
                .font(.caption)
            
            .foregroundStyle(Color(.tertiaryLabel))        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
