//
//  LoginView.swift
//  DocMate
//

import SwiftUI

struct LoginView: View {
    
    @Environment(AuthViewModel.self) var authVM
    @Environment(AppViewModel.self) var viewModel
    
    @State private var email = ""
    @State private var password = ""
    
    @State private var showPassword = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                
                // Background
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
                    VStack(spacing: 28) {
                        
                        Spacer()
                            .frame(height: 4)
                        
                        // MARK: Logo
                        VStack(spacing: 12) {
                            

                            Image("DOCLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 90, height: 90)
                            
                            Text("DocMate")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundStyle(.blue)
                            
                            Text("Securely manage your documents")
                                .font(.footnote)
                                .foregroundStyle(.secondary.opacity(0.85))
                        }
                        
                        // MARK: Heading
                        Text("Sign In")
                            .font(.system(size: 32, weight: .bold))
                            .padding(.top, 10)
                        
                        // MARK: Fields Card
                        VStack(spacing: 18) {
                            
                            // Email
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
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.blue.opacity(0.5), lineWidth: 1.2)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            
                            // Password
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.headline)
                                
                                HStack {
                                    Image(systemName: "lock")
                                        .foregroundStyle(.blue)
                                    
                                    Group {
                                        if showPassword {
                                            TextField("Enter your password", text: $password)
                                        } else {
                                            SecureField("Enter your password", text: $password)
                                        }
                                    }
                                    
                                    Button {
                                        showPassword.toggle()
                                    } label: {
                                        Image(systemName: showPassword ? "eye.slash" : "eye")
                                            .foregroundStyle(.blue)
                                    }
                                }
                                .padding()
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.blue.opacity(0.5), lineWidth: 1.2)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            
                            // Forgot Password
                            HStack {
                                Spacer()
                                
                                NavigationLink("Forgot Password?") {
                                    ForgotPasswordView()
                                }
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.blue)
                            }
                        }
                        
                        // Error
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .foregroundStyle(.red)
                                .font(.footnote)
                        }
                        
                        // MARK: Login Button
                        Button {
                            Task {
                                await login()
                            }
                        } label: {
                            Group {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Sign In")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                        }
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        
                        // MARK: Apple Sign In
                        AppleLoginButton()
                            .frame(height: 56)
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .fill(.gray.opacity(0.25))
                                .frame(height: 1)
                            
                            Text("or")
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                            
                            Rectangle()
                                .fill(.gray.opacity(0.25))
                                .frame(height: 1)
                        }
                        
                        
                        // Signup
                        HStack(spacing: 4) {
                            Text("Don't have an account?")
                                .foregroundStyle(.secondary)
                            
                            NavigationLink("Sign Up") {
                                SignupView()
                            }
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue)
                        }
                        .padding(.bottom, 30)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    func login() async {
        do {
            isLoading = true
            errorMessage = ""

            try await SupabaseManager.shared.signIn(
                email: email,
                password: password
            )

            viewModel.reset()
            authVM.isLoggedIn = true
            await viewModel.fetchAll()

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    LoginView()
        .environment(AuthViewModel())
        .environment(AppViewModel())
}
