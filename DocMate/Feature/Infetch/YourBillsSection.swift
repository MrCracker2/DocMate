//
//  YourBillsSection.swift
//  DocMate
//
//  Created by Naman Yadav on 24/03/26.
//

import SwiftUI

struct YourBillsSection: View {
    
    var bills: [Infetch]
    var upcomingBills: [Infetch] {
        bills
            .filter { !$0.isPaid && $0.dueDate >= Date() }
            .sorted { $0.dueDate < $1.dueDate }
            .prefix(4)
            .map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("Bills")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                NavigationLink(destination: AllBillsView()) {
                    HStack(spacing: 4) {
                        Text("See All")
                            .font(.system(size: 14, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 4)
            
            if !upcomingBills.isEmpty {
                BillsCarouselView(bills: upcomingBills)
            }
        }
    }
}
