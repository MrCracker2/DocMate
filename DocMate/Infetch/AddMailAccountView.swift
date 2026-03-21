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
        VStack(spacing: 24) {

            HStack {
                Spacer()
                Button {
                    hasAddedMail = true
                    goNext = true
                } label: {
                    Text("Next")
                        .padding()
                        .fontWeight(.semibold)
                        .background(isValid ? Color.blue : Color.gray.opacity(0.5))
                        .foregroundStyle(.white)
                        .cornerRadius(40)
                }
            }

            Text("Infetch")
                .font(.largeTitle)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer().frame(height: 20)

            VStack(spacing: 16) {
                Image(systemName: "envelope.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                Text("Add Mail Account")
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            VStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text("Email Address").font(.subheadline)
                    TextField("user@example.com", text: $email)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                VStack(alignment: .leading) {
                    Text("Password").font(.subheadline)
                    SecureField("Enter password", text: $password)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                }
            }

            Text("Sign in to your mail account provider")
                .font(.footnote)
                .foregroundColor(.gray)

            Spacer()
        }
        .padding()
        .background(Color(.systemGray5))
        .navigationDestination(isPresented: $goNext) {
            InFetchView()
        }
    }
}

#Preview {
    NavigationStack { AddMailAccountView() }
}
