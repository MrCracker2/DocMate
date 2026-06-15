//
//  SignupView.swift
//  DocMate
//
//  Created by Shashwat kumar on 23/04/26.
//

import SwiftUI

struct SignupView: View {
    
    @Environment(\.dismiss) var dismiss
    @Environment(AuthViewModel.self) var authVM
    @Environment(AppViewModel.self) var viewModel
    
    // Auth fields
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    
    // Profile fields
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var dateOfBirth = Date()
    @State private var gender = "Male"
    
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    let genderOptions = ["Male", "Female", "Other"]
    
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
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        Spacer()
                            .frame(height: 5)
                        
                        // MARK: Logo
                        VStack(spacing: 12) {
                            
                            Image("DOCLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 90, height: 90)
                            
                            Text("DocMate")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(.blue)
                            
                            Text("Create your secure account")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        // MARK: Title
                        Text("Sign Up")
                            .font(.system(size: 30, weight: .bold))
                        
                        // MARK: Fields
                        VStack(spacing: 16) {
                            
                            // Name fields
                            authField(
                                title: "First Name",
                                placeholder: "Enter your first name",
                                icon: "person",
                                text: $firstName
                            )
                            
                            authField(
                                title: "Last Name",
                                placeholder: "Enter your last name",
                                icon: "person.2",
                                text: $lastName
                            )
                            
                            // Email
                            authField(
                                title: "Email",
                                placeholder: "Enter your email",
                                icon: "envelope",
                                text: $email
                            )
                            
                            // Date of Birth
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Date of Birth")
                                    .font(.headline)
                                
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundStyle(.blue)
                                    
                                    DatePicker(
                                        "",
                                        selection: $dateOfBirth,
                                        displayedComponents: .date
                                    )
                                    .labelsHidden()
                                    
                                    Spacer()
                                }
                                .padding()
                                .background(.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.blue.opacity(0.45), lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            
                            // Gender
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Gender")
                                    .font(.headline)
                                
                                HStack {
                                    Image(systemName: "person.crop.circle")
                                        .foregroundStyle(.blue)
                                    
                                    Picker("Gender", selection: $gender) {
                                        ForEach(genderOptions, id: \.self) { option in
                                            Text(option)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                }
                                .padding()
                                .background(.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.blue.opacity(0.45), lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            
                            // Passwords
                            passwordField(
                                title: "Password",
                                placeholder: "Enter your password",
                                text: $password,
                                show: $showPassword
                            )
                            
                            passwordField(
                                title: "Confirm Password",
                                placeholder: "Confirm your password",
                                text: $confirmPassword,
                                show: $showConfirmPassword
                            )
                        }
                        
                        // Error
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .foregroundStyle(.red)
                                .font(.footnote)
                        }
                        
                        // MARK: Sign Up Button
                        Button {
                            Task {
                                await signUp()
                            }
                        } label: {
                            Group {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Create Account")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                        }
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        
                        // MARK: Already Account
                        HStack(spacing: 4) {
                            Text("Already have an account?")
                                .foregroundStyle(.secondary)
                            
                            Button("Sign In") {
                                dismiss()
                            }
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue)
                        }
                        .padding(.bottom, 30)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationBarBackButtonHidden()
    }

    // MARK: Sign Up
    func signUp() async {

        guard !firstName.isEmpty else {
            errorMessage = "Enter your first name"
            return
        }

        guard !lastName.isEmpty else {
            errorMessage = "Enter your last name"
            return
        }

        guard email.contains("@") else {
            errorMessage = "Invalid email"
            return
        }

        guard password.count >= 6 else {
            errorMessage = "Password must be 6+ characters"
            return
        }

        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }

        do {
            isLoading = true
            errorMessage = ""

            let fullName = "\(firstName) \(lastName)"

            try await SupabaseManager.shared.signUp(
                email: email,
                password: password,
                name: fullName,
                phone: nil,
                dateOfBirth: dateOfBirth,
                gender: gender
            )

            viewModel.reset()
            authVM.isLoggedIn = true
            await viewModel.fetchAll()

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
    
    // MARK: Components
    
    func authField(
        title: String,
        placeholder: String,
        icon: String,
        text: Binding<String>
    ) -> some View {
        
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.blue)
                
                TextField(placeholder, text: text)
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
    }
    
    func passwordField(
        title: String,
        placeholder: String,
        text: Binding<String>,
        show: Binding<Bool>
    ) -> some View {
        
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            HStack {
                Image(systemName: "lock")
                    .foregroundStyle(.blue)
                
                Group {
                    if show.wrappedValue {
                        TextField(placeholder, text: text)
                    } else {
                        SecureField(placeholder, text: text)
                    }
                }
                
                Button {
                    show.wrappedValue.toggle()
                } label: {
                    Image(systemName: show.wrappedValue ? "eye.slash" : "eye")
                        .foregroundStyle(.blue)
                }
            }
            .padding()
            .background(.white)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.blue.opacity(0.45), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

#Preview {
    SignupView()
        .environment(AuthViewModel())
        .environment(AppViewModel())
}
