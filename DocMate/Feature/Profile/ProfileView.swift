//
//  ProfileView.swift
//  DocMate
//
//  Created by Naman Yadav on 16/03/26.
//

import SwiftUI

struct ProfileView: View {
    
    @Environment(AppViewModel.self ) var viewModel
    @Environment(AuthViewModel.self) var authVM
    @State private var showEditSheet = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        
        NavigationStack {
            Form {
                
                // Profile Header
                Section {
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 120, height: 100)
                            
                            Text(viewModel.user.initials)
                                .font(.system(size: 40))
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
                // Profile Info
                Section {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(viewModel.user.name)
                            .foregroundStyle(.gray)
                    }
                    
                    HStack {
                        Text("Date of Birth")
                        Spacer()
                        Text(viewModel.user.dateOfBirth.formatted(date: .abbreviated, time: .omitted))
                            .foregroundStyle(.gray)
                    }
                    
                    HStack {
                        Text("Gender")
                        Spacer()
                        Text(viewModel.user.gender)
                            .foregroundStyle(.gray)
                    }
                }
                
                // Features
                Section{
                    NavigationLink("Notification") {
                        Text("Notification Screen")
                    }
                }
                
                // Info
                Section{
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
                
                // Logout
                Section {
                    Button("Logout") {
                        Task {
                            await logout()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.red)
                    .buttonStyle(.bordered)
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    }label: {
                        Image(systemName: "chevron.left")
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.plain)
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
    func logout() async {
        do {
            try await SupabaseManager.shared.signOut()
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
