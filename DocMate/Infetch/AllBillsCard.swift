//
//  AllBillsCard.swift
//  DocMate
//
//  Created by Naman Yadav on 31/03/26.
//


//
//  AllBillsCard.swift
//  DocMateDummy
//
//  Created by Naman Yadav on 25/03/26.
//


import SwiftUI

struct AllBillsCard: View {
    
    let doc: infetch
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
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(14)
        .shadow(radius: 2)
    }
}
