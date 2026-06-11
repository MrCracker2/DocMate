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
        
        Group {
            if !upcomingBills.isEmpty {
                BillsCarouselView(bills: upcomingBills)
            }
        }
    }
}
