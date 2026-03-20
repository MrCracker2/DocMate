//
//  DocumentRowView.swift
//  DocMate
//
//  Created by Shashwat kumar on 20/03/26.
//

import SwiftUI

struct DocumentRowView: View {
    
    var doc: Document
    var isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            
            // Icon
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 40, height: 40)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                
                Image(systemName: doc.fileType.sfSymbol)
                    .foregroundColor(.black)
            }
            
            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(doc.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Nov 15, 2025   106KB")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Selection
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1.5)
        )
    }
}

