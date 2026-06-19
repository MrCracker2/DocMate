//
//  BillDetailView.swift
//  DocMate
//
//  Created by Naman Yadav on 06/04/26.
//
import SwiftUI

struct BillDetailView: View {

    let doc: Infetch
    @Environment(\.openURL) private var openURL

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

            // Opens the source email in the Gmail app (or Gmail web if the app
            // isn't installed). Uses the stored Gmail message id.
            if let id = doc.gmailMessageId,
               let url = URL(string: "https://mail.google.com/mail/u/0/#all/\(id)") {
                Button {
                    openURL(url)
                } label: {
                    Label("View Original Email", systemImage: "envelope")
                        .font(.system(size: 16, weight: .medium))
                }
                .padding(.top, 4)
            }

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
