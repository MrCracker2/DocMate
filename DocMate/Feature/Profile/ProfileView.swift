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
    
    var body: some View {
        NavigationStack {
            Form {
                
                // MARK: Profile Header
                Section {
                    HStack {
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.25))
                                .frame(width: 110, height: 110)
                            
                            Text(viewModel.user.initials)
                                .font(.system(size: 38, weight: .semibold))
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 6)
                }
                .listRowBackground(Color.clear)
                
                // MARK: Profile Info
                Section("Personal Info") {
                    
                    profileRow(title: "Name", value: viewModel.user.name)
                    profileRow(title: "Date of Birth",
                               value: viewModel.user.dateOfBirth ?? "Not set")
                    profileRow(title: "Gender",
                               value: viewModel.user.gender ?? "Not set")
                }
                
                // MARK: App Settings
                Section("App Settings") {
                    
                    NavigationLink("Notification") {
                        Text("Notification Screen")
                    }
                    
                    NavigationLink("Account Management") {
                        AccountManagementView()
                    }
                }
                
                // MARK: Support
                Section("Support") {
                    
                    NavigationLink("Terms & Conditions") {
                        Text("Terms Screen")
                    }
                    
                    NavigationLink("Privacy Policy") {
                        Text("Privacy Screen")
                    }
                    
                    NavigationLink("Contact Support") {
                        Text("Support Screen")
                    }
                }
                
                // MARK: Bottom Sign Out Button
                Section {
                    HStack {
                        Spacer()
                        
                        Button {
                            Task { await logout() }
                        } label: {
                            HStack(spacing: 8) {
                               
                                
                                Text("Sign Out")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundStyle(.red)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color.red.opacity(0.12))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.red.opacity(0.25), lineWidth: 1)
                            )
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
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .fontWeight(.semibold)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") {
                        showEditSheet = true
                    }
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditProfileView()
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
                .foregroundStyle(.gray)
        }
    }
    
    func logout() async {
        do {
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
