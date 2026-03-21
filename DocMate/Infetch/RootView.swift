//
//  RootView.swift
//  DocMate
//
//  Created by Naman Yadav on 21/03/26.
//

import SwiftUI

struct RootView: View {

    @AppStorage("hasAddedMail") var hasAddedMail = false

    var body: some View {
        if !hasAddedMail {
            AddMailAccountView()
        } else {
            InFetchView()
        }
    }
}

#Preview {
    RootView()
        .environment(AppViewModel())
}
