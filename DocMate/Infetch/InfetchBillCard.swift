//
//  InfetchBillCard.swift
//  DocMate
//
//  Created by Naman Yadav on 31/03/26.
//


//
//  InfetchBillCard.swift
//  DocMateDummy
//
//  Created by Naman Yadav on 24/03/26.
//


import SwiftUI

struct InfetchBillCard: View {
    
    let doc: infetch
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 12) {
            
            HStack {
                Text(doc.name)
                    .font(.headline)
                
                Spacer()
                
                Text(doc.inFetchCatgogry.rawValue)
                    .font(.caption)
                    .padding(6)
                    .background(Color.blue.opacity(0.15))
                    .cornerRadius(8)
            }
            
            if let amount = doc.amount {
                Text("₹\(amount, specifier: "%.0f")")
                    .font(.title3)
                    .fontWeight(.bold)
            }
            
            Text(doc.SubjectName)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Text(doc.dueDate, style: .date)
                .font(.caption)
                .foregroundColor(.red)
        }
        .padding()
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
