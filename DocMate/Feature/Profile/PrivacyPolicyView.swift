//
//  PrivacyPolicyView.swift
//  DocMate
//

import SwiftUI

struct PrivacyPolicyView: View {

    private let lastUpdated = "September 2026"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                Text("Last updated: \(lastUpdated)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                policySection(
                    title: "1. Information We Collect",
                    body: """
                    DocMate collects the following information when you create an account or use the app:

                    • Name, email address, date of birth, and gender (provided during sign-up)
                    • Documents you scan, photograph, or upload
                    • Bill data extracted from Gmail emails (only when you connect Gmail)
                    • Notification preferences stored locally on your device
                    """
                )

                policySection(
                    title: "2. How We Use Your Information",
                    body: """
                    We use your information solely to provide and improve DocMate's features:

                    • To store and sync your documents securely across your devices
                    • To send you expiry and due-date reminders via push notifications
                    • To detect and import bills from your Gmail (only with your explicit consent)
                    • To display your profile information within the app
                    """
                )

                policySection(
                    title: "3. Gmail Data",
                    body: """
                    If you choose to connect Gmail:

                    • We request read-only access to your Gmail messages
                    • We only scan emails from the last 30 days
                    • We extract bill-related information (amounts, due dates, merchants)
                    • We do not read, store, or transmit the full body of your emails
                    • We cannot send, delete, or modify your Gmail messages
                    • You can disconnect Gmail at any time from Profile → Email Sync
                    """
                )

                policySection(
                    title: "4. Data Storage & Security",
                    body: """
                    • Your data is stored on Supabase (PostgreSQL) with row-level security — only you can access your data
                    • Documents are stored in encrypted Supabase Storage buckets
                    • We use HTTPS/TLS for all data transmission
                    • We do not sell your personal data to third parties
                    """
                )

                policySection(
                    title: "5. Data Deletion",
                    body: """
                    You may permanently delete your account and all associated data at any time from Profile → Account Management → Delete Account.

                    Upon deletion, we remove:
                    • All your documents and uploaded files
                    • Your bills and financial records
                    • Your profile information
                    • Your account credentials
                    """
                )

                policySection(
                    title: "6. Third-Party Services",
                    body: """
                    DocMate uses the following third-party services:

                    • Supabase — for authentication, database, and file storage
                    • Google Gmail API — for optional bill detection (only when connected)
                    • Apple Sign In — for optional Apple ID authentication

                    Each service has its own privacy policy.
                    """
                )

                policySection(
                    title: "7. Contact",
                    body: """
                    If you have any questions about this Privacy Policy, please contact us at:

                    kumarshashwat888@gmail.com
                    """
                )
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func policySection(title: String, body: String) -> some View {
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
        PrivacyPolicyView()
    }
}
