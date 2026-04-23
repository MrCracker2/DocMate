//
//  ForgotPasswordView.swift
//  DocMate
//
//  Created by Shashwat kumar on 23/04/26.
//

import SwiftUI
internal import Auth
import Supabase

struct ForgotPasswordView: View {
    
    @State private var email = ""
    @State private var message = ""
    
    var body: some View {
        VStack(spacing: 20) {
            
            Text("Reset Password")
                .font(.largeTitle.bold())

            AuthTextField(
                title: "Email",
                icon: "envelope.fill",
                text: $email
            )

            Button("Send Reset Link") {
                Task {
                    await reset()
                }
            }
            .buttonStyle(.borderedProminent)

            Text(message)
                .foregroundColor(.green)

            Spacer()
        }
        .padding()
    }
    
    func reset() async {
        do {
            try await SupabaseManager.shared.client.auth
                .resetPasswordForEmail(email)
            
            message = "Reset email sent"
        } catch {
            message = error.localizedDescription
        }
    }
}
