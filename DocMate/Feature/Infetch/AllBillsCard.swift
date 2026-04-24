
//
//  AllBillsCard.swift
//  DocMateDummy
//
//  Created by Naman Yadav on 25/03/26.
//
//
//  AllBillsCard.swift
//  DocMate
//

import SwiftUI

struct AllBillsCard: View {
    
    let doc: Infetch
    var onMarkPaid: () -> Void

    @State private var isPaidLocally = false

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

            // Unpaid / Paid toggle
            HStack(spacing: 0) {

                Button {
                    // already unpaid — no action
                } label: {
                    Text("Unpaid")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(!isPaidLocally ? Color.orange.opacity(0.15) : Color.clear)
                        .foregroundStyle(!isPaidLocally ? Color.orange : Color.secondary)
                }
                .buttonStyle(.plain)
                .disabled(isPaidLocally)

                Divider().frame(height: 22)

                Button {
                    guard !isPaidLocally else { return }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isPaidLocally = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onMarkPaid()
                    }
                } label: {
                    Text("Paid")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(isPaidLocally ? Color.green.opacity(0.15) : Color.clear)
                        .foregroundStyle(isPaidLocally ? Color.green : Color.secondary)
                }
                .buttonStyle(.plain)
            }
            .background(Color.black.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .animation(.easeInOut(duration: 0.2), value: isPaidLocally)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(14)
        .shadow(radius: 2)
    }
}
