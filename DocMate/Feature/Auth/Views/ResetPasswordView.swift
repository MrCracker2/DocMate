//
//  ResetPasswordView.swift
//  DocMate
//
//  Created by Shashwat kumar on 12/06/26.
//


import SwiftUI
import Auth
import Supabase

struct ResetPasswordView: View {

    @Environment(\.dismiss) var dismiss

    @State private var password = ""
    @State private var confirmPassword = ""

    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var successMessage = ""

    var body: some View {

        ZStack {

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

            VStack(alignment: .leading, spacing: 24) {

                Spacer()
                    .frame(height: 20)

                Text("Reset Password")
                    .font(.system(size: 36, weight: .bold))

                Text("Enter your new password below.")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {

                    Text("New Password")
                        .font(.headline)

                    HStack {
                        Image(systemName: "lock")
                            .foregroundStyle(.blue)

                        SecureField(
                            "Enter new password",
                            text: $password
                        )
                    }
                    .padding()
                    .background(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.blue.opacity(0.45))
                    )
                    .clipShape(
                        RoundedRectangle(cornerRadius: 16)
                    )
                }

                VStack(alignment: .leading, spacing: 8) {

                    Text("Confirm Password")
                        .font(.headline)

                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.blue)

                        SecureField(
                            "Confirm password",
                            text: $confirmPassword
                        )
                    }
                    .padding()
                    .background(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.blue.opacity(0.45))
                    )
                    .clipShape(
                        RoundedRectangle(cornerRadius: 16)
                    )
                }

                if !successMessage.isEmpty {
                    Text(successMessage)
                        .foregroundStyle(.green)
                        .font(.footnote)
                }

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }

                Button {

                    Task {
                        await updatePassword()
                    }

                } label: {

                    Group {

                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Update Password")
                                .fontWeight(.semibold)
                        }

                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                }
                .background(Color.blue)
                .foregroundStyle(.white)
                .clipShape(
                    RoundedRectangle(cornerRadius: 18)
                )

                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }

    func updatePassword() async {

        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            return
        }

        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }

        do {

            isLoading = true
            errorMessage = ""

            try await SupabaseManager.shared.client.auth.update(
                user: UserAttributes(
                    password: password
                )
            )

            successMessage = "Password updated successfully."

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    ResetPasswordView()
}
