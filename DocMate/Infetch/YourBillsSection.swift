//
//  InfetchBillCard.swift
//  DocMateDummy
//
//  Created by Naman Yadav on 24/03/26.
//

import SwiftUI

struct YourBillsSection: View {
    
    var bills: [infetch]
    
    @State private var currentIndex = 0
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 16) {
            
            // Header
            HStack {
                Text("Your Bills")
                    .font(.title3)
                    .fontWeight(.bold)
                
                NavigationLink(destination: AllBillsView()) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
            }
            
            //  Apple Style Card Transition
            if !bills.isEmpty {
                ZStack {
                    BillsCarouselView(bills: bills)
                        .id(currentIndex) // important
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
                .animation(.easeInOut(duration: 1.0), value: currentIndex)
                .onAppear {
                    startAutoScroll()
                }
                .onChange(of: bills.count) {
                    if currentIndex >= bills.count {
                        currentIndex = max(0, bills.count - 1)
                    }
                }
            }
        }
    }
    
    //  Auto Change
    func startAutoScroll() {
        
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            
            if bills.isEmpty { return }
            
            withAnimation {
                currentIndex = Int.random(in: 0..<bills.count)
            }
        }
    }
}
