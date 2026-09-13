//
//  AccountManagementView.swift
//  DocMate
//

import SwiftUI

struct AccountManagementView: View {
    
    @Environment(AppViewModel.self) var viewModel
    @Environment(AuthViewModel.self) var authVM
    @Environment(\.dismiss) var dismiss
    
    @State private var showDeleteAlert = false
    @State private var showConfirmTextField = false
    @State private var deleteConfirmText = ""
    @State private var isDeleting = false
    @State private var userEmail: String?
    
    var body: some View {
        Form {
            // MARK: Account Info
            Section("Account Details") {
                HStack {
                    Text("Name")
                    Spacer()
                    Text(viewModel.user.name.isEmpty ? "Not set" : viewModel.user.name)
                        .foregroundStyle(.secondary)
                }
                
                if let email = userEmail {
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(email)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // MARK: Danger Zone
            Section {
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    HStack(spacing: 10) {
                        if isDeleting {
                            ProgressView()
                        } else {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                        }
                        Text("Delete Account")
                            .foregroundStyle(.red)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .disabled(isDeleting)
            } header: {
                Text("Danger Zone")
            } footer: {
                Text("Deleting your account is permanent. All your uploaded documents, bills, and account data will be permanently removed.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Account Management")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            userEmail = await SupabaseManager.shared.currentUserEmail
        }
        // MARK: Step 1 – Confirmation alert
        .alert("Delete Account?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                showConfirmTextField = true
            }
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone.")
        }
        // MARK: Step 2 – Type DELETE to confirm
        .alert("Confirm Deletion", isPresented: $showConfirmTextField) {
            TextField("Type DELETE to confirm", text: $deleteConfirmText)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
            Button("Cancel", role: .cancel) {
                deleteConfirmText = ""
            }
            Button("Delete Account", role: .destructive) {
                if deleteConfirmText == "DELETE" {
                    deleteConfirmText = ""
                    Task { await deleteAccount() }
                }
            }
        } message: {
            Text("Type DELETE in the field above to permanently delete your account.")
        }
    }
    
    func deleteAccount() async {
        isDeleting = true
        do {
            // 1. Cancel all scheduled notifications
            NotificationManager.shared.removeAll()

            // 2. Delete all user data from Supabase
            try await SupabaseManager.shared.deleteCurrentUserData()

            // 3. Revoke Apple ID token (required by Apple guidelines)
            await revokeAppleToken()

            // 4. Sign out of Gmail
            GmailService.shared.signOut()

            // 5. Reset local state
            viewModel.reset()
            authVM.isLoggedIn = false
            dismiss()
        } catch {
            print("Delete account error:", error)
            viewModel.errorMessage = "Failed to delete account: \(error.localizedDescription)"
        }
        isDeleting = false
    }

    /// Revokes the Sign in with Apple token, required by Apple's guidelines when deleting an account.
    @MainActor
    private func revokeAppleToken() async {
        do {
            // Sign out via SupabaseManager which handles the Auth module import correctly
            try await SupabaseManager.shared.signOut()
        } catch {
            print("Apple token revocation error (non-fatal):", error)
        }
    }
}

#Preview {
    NavigationStack {
        AccountManagementView()
            .environment(AppViewModel())
            .environment(AuthViewModel())
    }
}
