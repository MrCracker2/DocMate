//
//  SupportView.swift
//  DocMate
//

import SwiftUI

struct SupportView: View {

    private let supportEmail = "kumarshashwat888@gmail.com"

    var body: some View {
        Form {

            // MARK: Get in Touch
            Section("Get in Touch") {
                Button {
                    if let url = URL(string: "mailto:\(supportEmail)") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.12))
                                .frame(width: 40, height: 40)
                            Image(systemName: "envelope.fill")
                                .foregroundStyle(.blue)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Email Support")
                                .foregroundStyle(.primary)
                            Text(supportEmail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                            .font(.caption)
                    }
                }
            }

            // MARK: FAQs
            Section("Frequently Asked Questions") {
                faqRow(
                    q: "How do I scan a document?",
                    a: "Tap the + button on the Home tab and choose 'Scan Document'. Point your camera at the document and follow the on-screen prompts."
                )
                faqRow(
                    q: "How do I connect Gmail?",
                    a: "Go to the Bills tab → Email Sync → Connect Gmail. You'll be asked to sign in with your Google account. DocMate only reads bill-related emails."
                )
                faqRow(
                    q: "How do I delete my account?",
                    a: "Go to Profile → Account Management → Delete Account. This permanently removes all your data."
                )
                faqRow(
                    q: "My documents aren't syncing. What do I do?",
                    a: "Make sure you have an active internet connection. Pull down on the Home screen to refresh, or sign out and sign back in."
                )
            }

            // MARK: App Info
            Section("App Info") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Build")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Contact Support")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func faqRow(q: String, a: String) -> some View {
        DisclosureGroup(q) {
            Text(a)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
        .font(.subheadline)
    }
}

#Preview {
    NavigationStack {
        SupportView()
    }
}
