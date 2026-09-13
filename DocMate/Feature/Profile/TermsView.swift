//
//  TermsView.swift
//  DocMate
//

import SwiftUI

struct TermsView: View {

    private let lastUpdated = "September 2026"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                Text("Last updated: \(lastUpdated)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                termSection(
                    title: "1. Acceptance of Terms",
                    body: "By downloading or using DocMate, you agree to these Terms & Conditions. If you do not agree, please do not use the app."
                )

                termSection(
                    title: "2. Use of the App",
                    body: """
                    DocMate is designed for personal document and bill management. You agree to:

                    • Use the app only for lawful purposes
                    • Not attempt to reverse-engineer or tamper with the app
                    • Not upload illegal or harmful content
                    • Keep your account credentials confidential
                    """
                )

                termSection(
                    title: "3. Account",
                    body: """
                    You are responsible for maintaining the security of your account. DocMate is not liable for any loss resulting from unauthorized access to your account. You may delete your account at any time from Profile → Account Management.
                    """
                )

                termSection(
                    title: "4. Data & Content",
                    body: """
                    You retain ownership of all documents and data you upload to DocMate. By uploading content, you grant DocMate a limited license to store and process it solely for providing the service to you.
                    """
                )

                termSection(
                    title: "5. Gmail Integration",
                    body: """
                    The Gmail integration is optional and requires your explicit consent. DocMate uses read-only access to detect bills in your inbox. We cannot and do not send, delete, or modify your emails.
                    """
                )

                termSection(
                    title: "6. Limitation of Liability",
                    body: """
                    DocMate is provided 'as is' without warranty of any kind. We are not liable for any loss of data, financial loss, or damages arising from your use of the app. Always keep copies of important documents in a separate location.
                    """
                )

                termSection(
                    title: "7. Changes to Terms",
                    body: "We may update these terms from time to time. Continued use of the app after changes constitutes your acceptance of the new terms."
                )

                termSection(
                    title: "8. Contact",
                    body: "For questions about these terms, contact us at: kumarshashwat890@gmail.com"
                )
            }
            .padding()
        }
        .navigationTitle("Terms & Conditions")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func termSection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            Text(body)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    NavigationStack {
        TermsView()
    }
}
