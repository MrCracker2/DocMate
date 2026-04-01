
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
    @State private var timer: Timer?
    
    var body: some View {
        
        if !bills.isEmpty {
            
            ZStack {
                
                InfetchBillCard(doc: bills[currentIndex])
                    .id(currentIndex)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                
                VStack {
                    Spacer()
                    
                    HStack(spacing: 6) {
                        ForEach(0..<bills.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentIndex ? .white : .white.opacity(0.4))
                                .frame(width: index == currentIndex ? 8 : 6,
                                       height: index == currentIndex ? 8 : 6)
                        }
                    }
                    .padding(.bottom, 10)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: currentIndex)
            .onAppear { startAutoScroll() }
            .onDisappear { timer?.invalidate() }
        }
    }
    
    func startAutoScroll() {
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            guard !bills.isEmpty else { return }
            
            withAnimation {
                currentIndex = (currentIndex + 1) % bills.count
            }
        }
    }
}
