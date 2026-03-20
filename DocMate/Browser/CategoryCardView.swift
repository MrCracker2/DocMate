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
        .background(Color.blue.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
