
//
//  BillsCarouselView.swift
//  DocMateDummy
//
//  Created by Naman Yadav on 25/03/26.
//

import SwiftUI

struct BillsCarouselView: View {
    
    var bills: [infetch]
    @State private var currentIndex = 0
    
    var body: some View {
        
        if !bills.isEmpty {
            
            ZStack {
                
                // Card (FULL CHANGE)
                InfetchBillCard(doc: bills[currentIndex])
                    .id(currentIndex)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                
                // Dots (center bottom)
                VStack {
                    Spacer()
                    
                    HStack(spacing: 6) {
                        ForEach(0..<bills.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentIndex ? Color.white : Color.white.opacity(0.4))
                                .frame(width: 6, height: 6)
                        }
                    }
                    .padding(.bottom, 10)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: currentIndex)
        }
    }
}
