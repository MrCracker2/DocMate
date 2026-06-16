//
//  CategoryCardView.swift
//  DocMate
//
//  Created by Naman Yadav on 18/03/26.
//
import SwiftUI

struct CategoryCardView: View {
    let category: Category
    let docCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue, Color.blue.opacity(0.75)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 38, height: 38)
                
                Image(systemName: category.sfSymbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.bottom, 10)

            Spacer(minLength: 0)

            Text(category.name)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .lineLimit(2)

            Text("\(docCount) docs")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.blue.opacity(0.85))
                .padding(.top, 2)
        }
        .padding(12) //
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .topLeading) //
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.08), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}
struct TagRowView: View {
    let tag: Tag
    
    var color: Color {
        switch tag.color.lowercased() {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "yellow": return .yellow
        case "purple": return .purple
        case "orange": return .orange
        case "pink": return .pink
        default: return .gray
        }
    }
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 20, height: 20)
            
            Text(tag.name)
                .font(.system(size: 20))
                
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
    }
}
