//
//  FetchingView.swift
//  DocMate
//
//  Created by Shashwat kumar on 20/03/26.
//

import SwiftUI

struct FetchingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Fetching Document from Inbox")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    FetchingView()
}
