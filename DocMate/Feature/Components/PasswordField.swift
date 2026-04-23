//
//  PasswordField.swift
//  DocMate
//
//  Created by Shashwat kumar on 23/04/26.
//

import SwiftUI

struct PasswordField: View {
    
    @Binding var password: String
    @State private var isSecure = true
    
    var body: some View {
        HStack {
            Image(systemName: "lock.fill")
                .foregroundColor(.blue)

            if isSecure {
                SecureField("Password", text: $password)
            } else {
                TextField("Password", text: $password)
            }

            Button {
                isSecure.toggle()
            } label: {
                Image(systemName: isSecure ? "eye.slash" : "eye")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
