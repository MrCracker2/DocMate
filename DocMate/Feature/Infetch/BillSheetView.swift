//
//  PayBillSheetView.swift
//  DocMate
//
//  Created by Naman Yadav on 06/04/26.
//


import SwiftUI

struct BillSheetView: View {
    
    let doc: Infetch
    
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
            
            // Amount only — status removed
            HStack {
                VStack(alignment: .leading) {
                    Text("AMOUNT")
                    if let amount = doc.amount {
                        Text("₹\(amount, specifier: "%.2f")")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                }
                Spacer()
            }

            Divider()
            
            // Details
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Mobile No")
                        .foregroundStyle(.gray)
                    Spacer()
                    Text(doc.accountNumber)
                        .foregroundStyle(.gray)
                }
                HStack {
                    Text("Customer Name")
                        .foregroundStyle(.gray)
                    Spacer()
                    Text(doc.customerName)
                        .foregroundStyle(.gray)
                }
                HStack {
                    Text("Bill Number")
                        .foregroundStyle(.gray)
                    Spacer()
                    Text(doc.billNumber)
                        .foregroundStyle(.gray)
                }
                HStack {
                    Text("Bill Date")
                        .foregroundStyle(.gray)
                    Spacer()
                    Text(doc.billDate.formatted(date: .numeric, time: .omitted))
                        .foregroundStyle(.gray)
                }
                HStack {
                    Text("Due Date")
                        .foregroundStyle(.gray)
                    Spacer()
                    Text(doc.dueDate.formatted(date: .numeric, time: .omitted))
                        .foregroundStyle(.gray)
                }
            }
            Spacer()
        }
        .padding()
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
