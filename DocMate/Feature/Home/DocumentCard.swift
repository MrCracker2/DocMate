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
    var isPendingSync: Bool = false
    
    private var tintPair: (Color, Color) {
        (Color.blue, Color.blue.opacity(0.7))
    }
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 12) {
            
            HStack(alignment: .top) {
                ZStack {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [tintPair.0, tintPair.1],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                if isPendingSync {
                    Spacer()
                    Image(systemName: "cloud.sun.fill")
                        .symbolRenderingMode(.multicolor)
                        .font(.title3)
                    Image(systemName: "arrow.clockwise.icloud")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                }
            }
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            Spacer(minLength: 0)
            
            // Show Date if Exists
            if let dateText = dateText,
               let dateLabel = dateLabel {
                VStack(alignment: .leading, spacing: 2) {
                    Text(dateLabel.uppercased())
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(tintPair.0.opacity(0.82))
                    
                    Text(dateText)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 126, alignment: .topLeading)
        .background(
            ZStack {
                Color(.systemBackground)
                LinearGradient(
                    colors: [tintPair.0.opacity(0.16), tintPair.0.opacity(0.04)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: tintPair.0.opacity(0.08), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [tintPair.0.opacity(0.28), tintPair.1.opacity(0.14)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
    }
}
