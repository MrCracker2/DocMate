//
//  OnboardingView.swift
//  DocMate
//
//  Created by Naman Yadav on 25/04/26.
//

import SwiftUI

struct OnboardingView: View {
    
    @State private var currentPage = 0
    @State private var goToSignup = false
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding = false
    
    var body: some View {
        
        NavigationStack {
            
            ZStack {
                
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.15),
                        Color.white,
                        Color.blue.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack {
                    
                    Spacer()
                    
                    // Cards
                    TabView(selection: $currentPage) {
                        
                        OnboardingCard(
                            image: "tray.and.arrow.down.fill",
                            title: "Import Bills Easily",
                            subtitle: "Snap, upload or forward your bills in seconds"
                        )
                        .tag(0)
                        
                        OnboardingCard(
                            image: "viewfinder.circle.fill",
                            title: "Auto Detect Due Dates",
                            subtitle: "Smart scanning extracts dates so you don’t have to"
                        )
                        .tag(1)
                        
                        OnboardingCard(
                            image: "bell.badge.fill",
                            title: "Stay Ahead",
                            subtitle: "Get reminders before deadlines hit you"
                        )
                        .tag(2)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: 420)
                    
                    Spacer()
                    
                   
                    VStack(spacing: 16) {
                        
                        // Page Indicator
                        HStack(spacing: 6) {
                            ForEach(0..<3) { index in
                                Capsule()
                                    .fill(index == currentPage ? Color.blue : Color.gray.opacity(0.2))
                                    .frame(
                                        width: index == currentPage ? 20 : 6,
                                        height: 6
                                    )
                                    .animation(.easeInOut, value: currentPage)
                            }
                        }
                        
                        // Button
                        Button {
                            if currentPage < 2 {
                                currentPage += 1
                            } else {
                                hasSeenOnboarding = true
                                goToSignup = true
                            }
                        } label: {
                            Text(currentPage == 2 ? "Continue" : "Next")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [Color.blue, Color.blue.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                        }
                        
                        // Skip
                        Button("Skip") {
                            goToSignup = true
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.white.opacity(0.7))
                            .blur(radius: 0.5)
                    )
                    .padding(.horizontal)
                    
                }
                .navigationDestination(isPresented: $goToSignup) {
                    SignupView()
                }
            }
        }
    }
}
