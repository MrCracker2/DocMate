//
//  CategoryCardView.swift
//  DocMate
//
//  Created by Naman Yadav on 18/03/26.
//
import SwiftUI

// MARK: - Browse Category Card
struct CategoryCardView: View {
    let category: Category
    let docCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            Image(systemName: category.sfSymbol)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.bottom, 12)

            Spacer()

            Text(category.name)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Text("\(docCount) docs")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.75))
                .padding(.top, 2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .leading)
        .background(Color.blue.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Tag Row 
struct TagRowView: View {
    let tag: Tag

    var color: Color {
        switch tag.color.lowercased() {
        case "red":    return .red
        case "blue":   return .blue
        case "green":  return .green
        case "yellow": return .yellow
        case "purple": return .purple
        case "orange": return .orange
        case "pink":   return .pink
        default:       return .gray
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 15, height: 15)

            Text(tag.name)
                .font(.system(size: 18))
                .foregroundStyle(.primary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }
}
