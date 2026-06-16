//
//  BillDetailView.swift
//  DocMate
//
//  Created by Naman Yadav on 06/04/26.
//
import SwiftUI

struct BillDetailView: View {
    
    let doc: Infetch
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 16) {
            
            Text("All Details")
                .font(.system(size: 20))
            
            Divider()
            
            detailRow("Customer Name", doc.customerName)
            
            if let phone = doc.phoneNumber {
                detailRow("Mobile No", "\(phone)")
            }
            
            detailRow("Bill Number", doc.billNumber)
            detailRow("Bill Date", doc.billDate.formatted(date: .numeric, time: .omitted))
            detailRow("Due Date", doc.dueDate.formatted(date: .numeric, time: .omitted))
            
            Spacer()
        }
        .padding()
    }
    
    func detailRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
        }
    }
}
