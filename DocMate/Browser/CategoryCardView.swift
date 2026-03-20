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

    var accent: Color {
        let palette: [Color] = [
            Color(red: 0.32, green: 0.56, blue: 0.92),  // soft blue
            Color(red: 0.40, green: 0.72, blue: 0.64),  // mint green
            Color(red: 0.58, green: 0.68, blue: 0.94),  // lavender blue
            Color(red: 0.70, green: 0.78, blue: 0.88),  // cool gray blue
            Color(red: 0.55, green: 0.75, blue: 0.85),  // sky calm
            Color(red: 0.65, green: 0.82, blue: 0.70),  // soft green
            Color(red: 0.75, green: 0.78, blue: 0.92),  // pastel purple
            Color(red: 0.60, green: 0.70, blue: 0.80)   // neutral blue gray
        ]
        let i = abs(category.name.hashValue) % palette.count
        return palette[i]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            Image(systemName: category.sfSymbol)
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.bottom, 12)

            Spacer()

            Text(category.name)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Text("\(docCount) docs")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.75))
                .padding(.top, 2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [accent, accent.opacity(0.72)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: accent.opacity(0.35), radius: 10, x: 0, y: 5)
        )
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
