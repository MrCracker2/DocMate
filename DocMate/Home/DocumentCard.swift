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
    var dueDate: String? = nil
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 10) {
            
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.headline)
            // Show Date if Exists
            if let dueDate = dueDate {
                Text("Due: \(dueDate)")
                    .foregroundColor(.red)
                    .font(.subheadline)
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
#Preview {
    DocumentCard(icon: "doc.fill", title: "Sample Document")
}
