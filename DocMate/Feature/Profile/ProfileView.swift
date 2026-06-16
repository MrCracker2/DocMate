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
    @State private var showDeleteAlert = false
    @State private var isDeleting = false
    
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
                
                Section("Email"){
                    NavigationLink {
                        EmailSyncView()
                    } label: {
                        Label("Email Sync", systemImage: "envelope.badge")
                    }
                    NavigationLink {
                        BillsHistoryView()
                    } label: {
                        Label("Your Bills History",
                              systemImage: "clock.arrow.circlepath")
                    }
                    
                    
                }
                
                // MARK: Features
                Section("Features") {
                    
                    NavigationLink("Notification") {
                        Text("Notification Screen")
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
                
                // MARK: Logout
                Section("Sign Out") {
                    
                    Button {
                        Task { await logout() }
                    } label: {
                        HStack {
                            Label(
                                "Logout",
                                systemImage: "rectangle.portrait.and.arrow.right"
                            )
                            
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .foregroundStyle(.red)
                    
                    
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
                }
                
                
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
            .alert("Delete Account?", isPresented: $showDeleteAlert) {
                
                Button("Cancel", role: .cancel) { }
                
                Button("Delete", role: .destructive) {
                    Task { await deleteAccount() }
                }
                
            } message: {
                Text("All your documents, bills and account data will be permanently removed.")
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
            viewModel.reset()
            authVM.isLoggedIn = false
            dismiss()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func deleteAccount() async {
        isDeleting = true
        
        do {
            try await SupabaseManager.shared.deleteCurrentUserData()
            
            GmailService.shared.signOut()
            
            viewModel.reset()
            authVM.isLoggedIn = false
            dismiss()
            
        } catch {
            print(error.localizedDescription)
        }
        
        isDeleting = false
    }
}

#Preview {
    ProfileView()
        .environment(AppViewModel())
        .environment(AuthViewModel())
}
