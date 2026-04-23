
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
    
    var body: some View {
        
        HStack {
            
            VStack(alignment: .leading, spacing: 6) {
                
                Text(doc.SubjectName)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text(doc.name)
                    .font(.headline)
                
                if let amount = doc.amount {
                    Text("₹\(amount, specifier: "%.0f")")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Button(action: {
                onRefresh()
            }) {
                Text("Refresh")
            }
            .buttonStyle(.borderless)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(14)
        .shadow(radius: 2)
    }
}
