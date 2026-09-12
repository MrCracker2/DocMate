//
//  AppleLoginButton.swift
//  DocMate
//
//  Created by Shashwat kumar on 23/04/26.
//

import SwiftUI
import AuthenticationServices

// MARK: - AppleLoginButton

struct AppleLoginButton: View {

    @Environment(AuthViewModel.self) private var authVM
    @Environment(AppViewModel.self) private var viewModel

    @State private var errorMessage: String = ""

    var body: some View {
        VStack(spacing: 6) {
            SignInWithAppleButton(
                .signIn,
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: { result in
                    Task { @MainActor in
                        await handleCompletion(result)
                    }
                }
            )
            .signInWithAppleButtonStyle(.black)
            .frame(height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 18))

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Completion

    @MainActor
    private func handleCompletion(_ result: Result<ASAuthorization, Error>) async {
        errorMessage = ""

        switch result {
        case .failure(let error):
            let asError = error as? ASAuthorizationError
            print("[Apple Sign In] Error: \(error)")

            // Code 1001 = user tapped Cancel — ignore silently
            guard asError?.code != .canceled else { return }
            errorMessage = "Sign in with Apple failed. Please try again."

        case .success(let authorization):
            guard
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let identityTokenData = credential.identityToken,
                let idToken = String(data: identityTokenData, encoding: .utf8)
            else {
                errorMessage = "Apple did not return a valid token. Please try again."
                return
            }

            print("[Apple Sign In] Got idToken, calling Supabase…")

            // Name is only provided on the very FIRST Apple sign-in
            let fullName = credential.fullName?.formatted()

            do {
                try await authVM.signInWithApple(
                    idToken: idToken,
                    rawNonce: nil,
                    fullName: fullName,
                    viewModel: viewModel
                )
                print("[Apple Sign In] ✅ Success")
            } catch {
                print("[Apple Sign In] ❌ Supabase error: \(error)")
                let msg = error.localizedDescription
                errorMessage = msg.isEmpty ? "Sign in failed. Please try again." : msg
            }
        }
    }
}
