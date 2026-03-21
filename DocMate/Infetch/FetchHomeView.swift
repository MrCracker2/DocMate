//
//  FetchHomeView.swift
//  DocMate
//
//  Created by Naman Yadav on 20/03/26.
//

import SwiftUI

struct FetchHomeView: View {

    var onFetch: () -> Void

    var body: some View {
        // NavigationStack yahan nahi — ContentView mein already hai
        ScrollView (showsIndicators:false){
            VStack(spacing: 30) {

                Spacer().frame(height: 20)

                Button {
                    onFetch()
                } label: {
                    HStack {
                        Image(systemName: "envelope.fill")
                        Text("Fetch Documents from Mail")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(30)
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 20) {
                    Text("How it Works")
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(spacing: 18) {
                        StepRow(number: "1", title: "Scan Inbox",             desc: "We securely scan your emails for attachments")
                        StepRow(number: "2", title: "Filter Important Files", desc: "Bills, receipts and useful docs are detected")
                        StepRow(number: "3", title: "Import & Organize",      desc: "Everything is saved neatly in one place")
                    }
                }
                .padding(20)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .padding(.horizontal)
            }
        }
        .background(Color(.systemGray5).ignoresSafeArea())
        .navigationTitle("InFetch")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        FetchHomeView { print("Fetch tapped") }
    }
}
