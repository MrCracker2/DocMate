//
//  AddMailAccountView.swift
//  DocMate
//
//  Created by Naman Yadav on 21/03/26.
//

import SwiftUI

struct AddMailAccountView: View {

    @State private var email = ""
    @State private var password = ""
    @State private var goNext = false
    @AppStorage("hasAddedMail") var hasAddedMail = false

    var isValid: Bool {
        email.contains("@") && password.count >= 4
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {

                Text("Infetch")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Spacer().frame(height: 8)

                VStack(spacing: 16) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text("Add Mail Account")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)

                Spacer().frame(height: 8)

                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email Address")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        TextField("user@example.com", text: $email)
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Password")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        SecureField("Enter password", text: $password)
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                Text("Sign in to your mail account provider")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding()
            .padding(.top, 8)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    hasAddedMail = true
                    goNext = true
                } label: {
                    HStack(spacing: 4) {
                        Text("Next")
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .padding()
                    .fontWeight(.semibold)
                    .foregroundStyle(isValid ? .blue : Color(.tertiaryLabel))
                }
                .buttonStyle(.plain)
                .disabled(!isValid)
                .animation(.easeInOut(duration: 0.15), value: isValid)
            }
        }
        .navigationDestination(isPresented: $goNext) {
            InFetchView()
        }
    }
}
#Preview {
    NavigationStack{
        AddMailAccountView()
    }
}
