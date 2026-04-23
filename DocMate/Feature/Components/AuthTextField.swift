//
//  AuthTextField.swift
//  DocMate
//
//  Created by Shashwat kumar on 23/04/26.
//

import SwiftUI

struct AuthTextField: View {
    
    let title: String
    let icon: String
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)

            TextField(title, text: $text)
                .textInputAutocapitalization(.never)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
