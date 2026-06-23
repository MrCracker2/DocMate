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
        
<<<<<<< HEAD
        Group {
=======
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Text("Your Bills")
                    .font(.title3)
                    .fontWeight(.bold)
                
                NavigationLink(destination: AllBillsView()) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
            }
            
>>>>>>> Developer
            if !upcomingBills.isEmpty {
                BillsCarouselView(bills: upcomingBills)
            }
        }
    }
}
