//
//  DocumentCard.swift
//  DocMate
//
//  Created by Shashwat kumar on 19/03/26.
//

import SwiftUI
struct DocumentCard: View {
    
    var icon: String
    var title: String
    var dateText: String? = nil
    var dateLabel: String? = nil
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 10) {
            
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.headline)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            // Show Date if Exists
            if let dateText = dateText,
               let dateLabel = dateLabel {
                
                Text("\(dateLabel): \(dateText)")
                    .font(.subheadline)
                    .foregroundColor(.indigo)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.gray.opacity(0.1), Color.cyan.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
    }
}
