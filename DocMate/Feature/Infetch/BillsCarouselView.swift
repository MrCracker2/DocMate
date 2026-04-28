
//
//  BillsCarouselView.swift
//  DocMateDummy
//
//  Created by SHASHWAT KUMAR on 25/03/26.
//


import SwiftUI

struct BillsCarouselView: View {
    
    var bills: [Infetch]
    
    @State private var currentIndex = 1
    
    private var loopBills: [Infetch] {
        guard bills.count > 1 else { return bills }
        
        var items = bills
        items.insert(bills.last!, at: 0)
        items.append(bills.first!)
        return items
    }
    
    var body: some View {
        
        if !bills.isEmpty {
            
            ZStack {
                
                TabView(selection: $currentIndex) {
                    
                    ForEach(loopBills.indices, id: \.self) { index in
                        InfetchBillCard(doc: loopBills[index])
                            .tag(index)
                            .padding(.horizontal, 2)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 160)
                .onChange(of: currentIndex) { _, newValue in
                    
                    guard bills.count > 1 else { return }
                    
                    // Last fake card -> jump to first real
                    if newValue == loopBills.count - 1 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            currentIndex = 1
                        }
                    }
                    
                    // First fake card -> jump to last real
                    if newValue == 0 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            currentIndex = loopBills.count - 2
                        }
                    }
                }
                
                // Dots
                VStack {
                    Spacer()
                    
                    HStack(spacing: 6) {
                        ForEach(0..<bills.count, id: \.self) { index in
                            
                            Circle()
                                .fill(
                                    realIndex == index
                                    ? Color.blue
                                    : Color.blue.opacity(0.28)
                                )
                                .frame(
                                    width: realIndex == index ? 8 : 6,
                                    height: realIndex == index ? 8 : 6
                                )
                                .animation(.easeInOut, value: realIndex)
                        }
                    }
                    .padding(.bottom, 10)
                }
            }
        }
    }
    
    private var realIndex: Int {
        guard bills.count > 1 else { return 0 }
        
        if currentIndex == 0 {
            return bills.count - 1
        } else if currentIndex == loopBills.count - 1 {
            return 0
        } else {
            return currentIndex - 1
        }
    }
}
