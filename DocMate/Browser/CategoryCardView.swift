//
//  CategoryCardView.swift
//  DocMate
//
//  Created by Naman Yadav on 18/03/26.
//

import SwiftUI

struct CategoryCardView: View {
    let category: Category
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: category.sfSymbol)
                .font(.system(size: 36))
                .foregroundStyle(.blue)
            
            Text(category.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(Color(.systemGray6))
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
