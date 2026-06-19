//
//  EmailViewerView.swift
//  DocMate
//
//  Shows a bill's source Gmail email inside the app, fetched on demand via
//  GmailService. Keeps the user in DocMate instead of bouncing to Safari/Gmail.
//

import SwiftUI

struct EmailViewerView: View {

    /// The Gmail message id stored on the bill (`Infetch.gmailMessageId`).
    let messageId: String

    @Environment(\.dismiss) private var dismiss

    @State private var email: GmailEmail?
    @State private var errorMessage: String?
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading email…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let email {
                    content(for: email)
                } else {
                    errorState
                }
            }
            .navigationTitle("Email")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .task { await load() }
    }

    private func content(for email: GmailEmail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(email.subject)
                    .font(.headline)

                HStack(spacing: 6) {
                    Text(email.from)
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                    Spacer()
                    Text(email.receivedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.gray)
                }

                Divider()

                Text(email.body.isEmpty ? "No content available." : email.body)
                    .font(.body)
                    .textSelection(.enabled)
            }
            .padding()
        }
    }

    private var errorState: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text(errorMessage ?? "Couldn't load this email.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.gray)
            Button("Try Again") {
                Task { await load() }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            email = try await GmailService.shared.fetchEmail(id: messageId)
        } catch {
            email = nil
            errorMessage = GmailService.shared.isSignedIn
                ? "Couldn't load this email. Please try again."
                : "Please connect your Gmail account to view this email."
        }
        isLoading = false
    }
}
