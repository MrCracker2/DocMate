//
//  AppleLoginButton.swift
//  DocMate
//
//  Created by Shashwat kumar on 23/04/26.
//

import SwiftUI

import SwiftUI
import AuthenticationServices

struct AppleLoginButton: View {
    
    var body: some View {
        SignInWithAppleButton(
            .signIn,
            onRequest: { request in
                
            },
            onCompletion: { result in
                
            }
        )
        .signInWithAppleButtonStyle(.black)
        .frame(height: 50)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
