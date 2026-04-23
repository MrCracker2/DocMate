import SwiftUI

struct LoginView: View {
    
    @Environment(AuthViewModel.self) var authVM
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                
                Spacer()
                
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.blue)
                
                Text("Welcome to DocMate")
                    .font(.largeTitle.bold())
                
                VStack(spacing: 16) {
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                }
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                }
                
                Button {
                    Task { await login() }
                } label: {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Login")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .frame(height: 50)
                
                AppleLoginButton()
                    .frame(height: 50)
                
                NavigationLink("Forgot Password?") {
                    ForgotPasswordView()
                }
                .font(.footnote)
                
                Spacer()
                
                NavigationLink("Create Account") {
                    SignupView()
                }
            }
            .padding()
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
            
            authVM.isLoggedIn = true
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
