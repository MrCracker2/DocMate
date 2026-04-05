//
//  PayBillSheetView.swift
//  DocMate
//
//  Created by Naman Yadav on 06/04/26.
//


import SwiftUI

struct BillSheetView: View {
    
    let doc: Infetch
    @State private var showDetails = false
    
    var body: some View {
        
        VStack(spacing: 20) {
            
            // Header
            VStack(alignment: .leading, spacing: 8) {
                
                Text(doc.name)
                    .font(.headline)
                
                Text(doc.SubjectName)
                    .foregroundColor(.gray)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.blue.opacity(0.15))
            .cornerRadius(8)
            
            HStack{
                // Amount
                VStack(alignment:.leading){
                    Text("AMOUNT")
                    if let amount = doc.amount {
                        Text("₹\(amount, specifier: "%.2f")")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                }
                Spacer()
                // Status
                Text(doc.isPaid ? "Paid" : "Overdue")
                    .font(.caption)
                    .padding(6)
                    .background(doc.isPaid ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                    .cornerRadius(6)
            }
            Divider()
            
            // Details preview
            VStack(alignment:.leading , spacing: 8){
                HStack{
                    Text("mobile no")
                        .foregroundStyle(.gray)
                    Spacer()
                    Text("\(doc.accountNumber)")
                        .foregroundStyle(.gray)
                }
                HStack{
                    Text("custumer name")
                        .foregroundStyle(.gray)
                    Spacer()
                    Text("\(doc.customerName)")
                        .foregroundStyle(.gray)
                }
                Button {
                    showDetails = true
                } label: {
                    Text("View more detail")
                        .bold()
                        .foregroundColor(.blue)
                        .padding(.vertical , 8)
                        .underline()
                }
            }
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showDetails) {
            BillDetailView(doc: doc)
                .presentationDetents([.medium, .large])
        }
    }
}
#Preview {
    BillSheetView(doc: Infetch(
        name: "Airtel Postpaid",
        dueDate: Date().addingTimeInterval(86400 * 2),
        billDate: Date().addingTimeInterval(-86400 * 28),
        SubjectName: "Airtel",
        amount: 664.34,
        customerName: "Neelam Gupta",
        accountNumber: "9711225575",
        billNumber: "MF26091012081043",
        isPaid: false,
        inFetchCatgogry: .bill
    ))
}
