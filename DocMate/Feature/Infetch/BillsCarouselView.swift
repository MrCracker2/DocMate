
//
//  BillsCarouselView.swift
//  DocMateDummy
//
//  Created by Naman Yadav on 25/03/26.
//
import SwiftUI

struct BillsCarouselView: View {
    
    var bills: [Infetch]
    @State private var currentIndex = 0
    
    var body: some View {
        
        if !bills.isEmpty {
            
            ZStack {
                
                //  Swipe Carousel
                TabView(selection: $currentIndex) {
                    
                    ForEach(bills.indices, id: \.self) { index in
                        InfetchBillCard(doc: bills[index])
                            .tag(index)
                            .padding(.horizontal, 2)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 160)
                .onChange(of: currentIndex) { oldValue, newValue in
                    
                    // swipe right at last → go to first
                    if newValue == bills.count - 1 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            currentIndex = 0
                        }
                    }
                    
                    // swipe left at first → go to last
                    if newValue == 0 && oldValue == 0 {
                        currentIndex = bills.count - 1
                    }
                }
                
                // Custom Dots (inside card)
                VStack {
                    Spacer()
                    
                    HStack(spacing: 6) {
                        ForEach(0..<bills.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentIndex ? Color.white : Color.white.opacity(0.4))
                                .frame(width: index == currentIndex ? 8 : 6,
                                       height: index == currentIndex ? 8 : 6)
                                .animation(.easeInOut, value: currentIndex)
                        }
                    }
                    .padding(.bottom, 10)
                }
            }
        }
    }
}
