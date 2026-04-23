//
//  SignupView.swift
//  DocMate
//
//  Created by Shashwat kumar on 23/04/26.
//

import SwiftUI

struct SignupView: View {
    
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var error = ""
    
    var body: some View {
        VStack(spacing: 18) {
            
            Text("Create Account")
                .font(.largeTitle.bold())

            AuthTextField(
                title: "Full Name",
                icon: "person.fill",
                text: $name
            )

            AuthTextField(
                title: "Email",
                icon: "envelope.fill",
                text: $email
            )

            PasswordField(password: $password)

            Button("Create Account") {
                Task {
                    await signup()
                }
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            .frame(height: 50)

            Spacer()
        }
        .padding()
    }
    
    func signup() async {
        guard email.contains("@") else {
            error = "Invalid email"
            return
        }

        do {
            try await SupabaseManager.shared.signUp(
                email: email,
                password: password
            )
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
