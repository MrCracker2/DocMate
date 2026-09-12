//
//  ProfileView.swift
//  DocMate
//

import SwiftUI

struct ProfileView: View {
    
    @Environment(AppViewModel.self) var viewModel
    @Environment(AuthViewModel.self) var authVM
    @Environment(\.dismiss) var dismiss
    
    @State private var showEditSheet = false
    @State private var showLogoutAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                
                // MARK: Profile Header
                Section {
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.12))
                                .frame(width: 110, height: 110)
                            Text(viewModel.user.initials.isEmpty ? "?" : viewModel.user.initials)
                                .font(.largeTitle.weight(.semibold))
                                .foregroundStyle(.blue)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 6)
                }
                .listRowBackground(Color.clear)
                
                // MARK: Profile Info
                Section("Personal Info") {
                    profileRow(title: "Name",
                               value: viewModel.user.name.isEmpty ? "Not set" : viewModel.user.name)
                    profileRow(title: "Date of Birth",
                               value: viewModel.user.dateOfBirth ?? "Not set")
                    profileRow(title: "Gender",
                               value: viewModel.user.gender ?? "Not set")
                }
                
                // MARK: App Settings
                Section("App Settings") {
                    NavigationLink("Notifications") {
                        NotificationSettingsView()
                    }
                    NavigationLink("Account Management") {
                        AccountManagementView()
                            .environment(viewModel)
                            .environment(authVM)
                    }
                }
                
                // MARK: Support & Legal
                Section("Support & Legal") {
                    NavigationLink("Terms & Conditions") {
                        TermsView()
                    }
                    NavigationLink("Privacy Policy") {
                        PrivacyPolicyView()
                    }
                    NavigationLink("Contact Support") {
                        SupportView()
                    }
                }
                
                // MARK: Sign Out Button
                Section {
                    HStack {
                        Spacer()
                        Button {
                            showLogoutAlert = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Sign Out")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundStyle(.red)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color.red.opacity(0.10))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.red.opacity(0.25), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") { showEditSheet = true }
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditProfileView()
                .environment(viewModel)
        }
        .alert("Sign Out?", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                Task { await logout() }
            }
        } message: {
            Text("You will be signed out of your account.")
        }
    }
}

// MARK: Helpers
extension ProfileView {
    
    @ViewBuilder
    func profileRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
    
    func logout() async {
        do {
            // Cancel all pending notifications on logout for privacy
            NotificationManager.shared.removeAll()
            try await SupabaseManager.shared.signOut()
            GmailService.shared.signOut()
            viewModel.reset()
            authVM.isLoggedIn = false
            dismiss()
        } catch {
            print(error.localizedDescription)
        }
    }
}

#Preview {
    ProfileView()
        .environment(AppViewModel())
        .environment(AuthViewModel())
}
