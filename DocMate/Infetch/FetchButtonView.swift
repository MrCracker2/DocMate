//
//  FetchButtonView.swift
//  DocMate
//
//  Created by Shashwat kumar on 20/03/26.
//

import SwiftUI

struct FetchButtonView: View {
    
    var onFetch: () -> Void
    
    var body: some View {
        VStack {
            
            HStack {
                Text("InFetch")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            .padding(.horizontal)
            
            Spacer()
            
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
                .background(Color.blue)
                .cornerRadius(12)
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
}


