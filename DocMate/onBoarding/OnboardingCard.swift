//
//  OnboardingCard.swift
//  DocMate
//
//  Created by Naman Yadav on 25/04/26.
//

import SwiftUI

struct OnboardingCard: View {
    
    let image: String
    let title: String
    let subtitle: String
    
    @State private var animate = false
    
    var body: some View {
        
        VStack(spacing: 24) {
            
            Spacer()
            
            
            ZStack {
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 140, height: 140)
                
                Image(systemName: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.blue)
            }
            
            // Texts
            VStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 26, weight: .semibold))
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 20, y: 10)
        )
        .padding(.horizontal, 24)
        .scaleEffect(animate ? 1 : 0.95)
        .opacity(animate ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                animate = true
            }
        }
    }
}
