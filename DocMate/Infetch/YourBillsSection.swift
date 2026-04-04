//
//  YourBillsSection.swift
//  DocMate
//
//  Created by Naman Yadav on 24/03/26.
//

import SwiftUI

struct YourBillsSection: View {
    
    var bills: [Infetch]
    
    // only 4 nearest upcoming bills
    var upcomingBills: [Infetch] {
        bills
            .filter { $0.dueDate >= Date() }
            .sorted { $0.dueDate < $1.dueDate }
            .prefix(4)
            .map { $0 }
    }
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 16) {
            
            HStack {
                Text("Your Bills")
                    .font(.title3)
                    .fontWeight(.bold)
                
                NavigationLink(destination: AllBillsView()) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
            }
            
            if !upcomingBills.isEmpty {
                BillsCarouselView(bills: upcomingBills)
            }
        }
    }
}
