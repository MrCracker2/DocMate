//
//  ForgotPasswordView.swift
//  DocMate
//

import SwiftUI
import Supabase

struct ForgotPasswordView: View {
    
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var isLoading = false
    @State private var message = ""
    @State private var errorMessage = ""
    
    var body: some View {
        
            ZStack {
                
                // MARK: Background
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.08),
                        Color.white,
                        Color.blue.opacity(0.04)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 28) {
                    
                    Spacer()
                        .frame(height: 20)
                    
                    // MARK: Title
                    Text("Forgot Password")
                        .font(.system(size: 36, weight: .bold))
                    
                    Text("Enter your email address and we'll send you a reset link to recover your password.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    
                    // MARK: Email Field
                    VStack(alignment: .leading, spacing: 8) {
                        
                        Text("Email")
                            .font(.headline)
                        
                        HStack {
                            Image(systemName: "envelope")
                                .foregroundStyle(.blue)
                            
                            TextField("Enter your email", text: $email)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }
                        .padding()
                        .background(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.blue.opacity(0.45), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    // Success Message
                    if !message.isEmpty {
                        Text(message)
                            .foregroundStyle(.green)
                            .font(.footnote)
                    }
                    
                    // Error Message
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                    
                    // MARK: Reset Button
                    Button {
                        Task {
                            await sendResetLink()
                        }
                    } label: {
                        Group {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Send Reset Link")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                    }
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .disabled(email.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                    .opacity(
                        email.trimmingCharacters(in: .whitespaces).isEmpty || isLoading
                        ? 0.6 : 1
                    )
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
            }

        
    }
    
    // MARK: Send Reset Link
    func sendResetLink() async {
        
        guard email.contains("@") else {
            errorMessage = "Please enter a valid email"
            return
        }
        
        do {
            isLoading = true
            errorMessage = ""
            message = ""
            
            try await SupabaseManager.shared.client.auth
                .resetPasswordForEmail(email)
            
            message = "Reset link sent successfully."
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

#Preview {
    ForgotPasswordView()
}
