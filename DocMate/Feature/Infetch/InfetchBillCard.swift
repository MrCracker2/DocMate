//
//  InfetchBillCard.swift
//  DocMateDummy
//
//  Created by Naman Yadav on 24/03/26.
//
import SwiftUI

struct InfetchBillCard: View {
    
    let doc: Infetch
    
    private var tintPair: (Color, Color) {
        (Color.blue, Color.blue.opacity(0.7))
    }
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 6) {
            
            HStack {
                Text(doc.name)
                    .font(.headline)
                
                Spacer()
                
                Text(doc.inFetchCategory.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.blue.opacity(0.14))
                    )
            }
            
            if let amount = doc.amount {
                Text("₹\(amount, specifier: "%.0f")")
                    .font(.title3)
                    .fontWeight(.bold)
            }
            
            Text(doc.subjectName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text("Due \(doc.dueDate, style: .date)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.blue.opacity(0.85))
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 138, maxHeight: 138, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [tintPair.0.opacity(0.08), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
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
