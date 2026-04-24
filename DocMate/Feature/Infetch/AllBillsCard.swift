
//
//  AllBillsCard.swift
//  DocMateDummy
//
//  Created by Naman Yadav on 25/03/26.
//


import SwiftUI

struct AllBillsCard: View {
    
    let doc: Infetch
    var onRefresh: () -> Void
    
    private var tintPair: (Color, Color) {
        (Color.blue, Color.blue.opacity(0.7))
    }
    
    var body: some View {
        
        HStack {
            
            VStack(alignment: .leading, spacing: 6) {
                
                Text(doc.SubjectName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(doc.name)
                    .font(.headline)
                
                if let amount = doc.amount {
                    Text("₹\(amount, specifier: "%.0f")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: {
                onRefresh()
            }) {
                Text("Refresh")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.blue.opacity(0.12))
                    )
            }
            .buttonStyle(.borderless)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [tintPair.0.opacity(0.08), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [tintPair.0.opacity(0.2), tintPair.1.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}
