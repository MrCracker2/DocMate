//
//  EmailSyncView.swift
//  DocMate
//
//  Created by Shashwat kumar on 27/04/26.
//
//

//

import SwiftUI

struct EmailSyncView: View {

    @State private var syncVM = EmailSyncViewModel()
    @Environment(AppViewModel.self) private var appViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {

                // MARK: - Hero
                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.10))
                            .frame(width: 92, height: 92)

                        Image(systemName: "envelope.badge.fill")
                            .font(.system(size: 38, weight: .medium))
                            .foregroundStyle(.blue)
                            .symbolEffect(.pulse, isActive: syncVM.isSyncing)
                    }

                    VStack(spacing: 6) {
                        Text("Gmail Bill Sync")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Connect Gmail to automatically detect and import your bills into DocMate.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                    }
                }
                .padding(.top, 18)

                // MARK: - Connection Status
                HStack(spacing: 8) {
                    Circle()
                        .fill(syncVM.isGmailConnected ? .green : .gray)
                        .frame(width: 10, height: 10)

                    Text(syncVM.isGmailConnected ? "Connected to Gmail" : "Not Connected")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // MARK: - Last Sync
                if let last = syncVM.lastSyncDate {
                    Text("Last synced: \(last.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // MARK: - Stats
                if syncVM.syncedCount > 0 || syncVM.skippedCount > 0 {
                    HStack(spacing: 12) {

                        StatCard(
                            icon: "checkmark.circle.fill",
                            value: "\(syncVM.syncedCount)",
                            label: "Imported",
                            color: .green
                        )

                        StatCard(
                            icon: "arrow.counterclockwise",
                            value: "\(syncVM.skippedCount)",
                            label: "Skipped",
                            color: .orange
                        )
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // MARK: - Progress
                if syncVM.isSyncing {
                    HStack(spacing: 12) {
                        ProgressView()
                            .tint(.blue)

                        Text(syncVM.currentStep)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Spacer()
                    }
                    .padding(14)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                // MARK: - Success
                if syncVM.showSuccessBanner {
                    BannerView(
                        icon: "checkmark.circle.fill",
                        title: "Sync Complete",
                        message: "\(syncVM.syncedCount) new bill\(syncVM.syncedCount == 1 ? "" : "s") imported.",
                        tint: .green
                    )
                }

                // MARK: - Error
                if syncVM.showError {
                    BannerView(
                        icon: "exclamationmark.triangle.fill",
                        title: "Sync Failed",
                        message: syncVM.errorMessage,
                        tint: .red
                    )
                }

                // MARK: - Primary Button
                Button {
                    Task {
                        guard let vc = getRootViewController() else { return }

                        await syncVM.startSync(
                            presenting: vc,
                            appViewModel: appViewModel
                        )
                    }
                } label: {

                    HStack(spacing: 10) {

                        if syncVM.isSyncing {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.85)

                            Text("Syncing...")
                                .fontWeight(.semibold)

                        } else {

                            Image(systemName:
                                    syncVM.isGmailConnected
                                  ? "arrow.triangle.2.circlepath"
                                  : "envelope.fill"
                            )

                            Text(syncVM.isGmailConnected ? "Sync Again" : "Connect Gmail")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(syncVM.isSyncing ? Color.blue.opacity(0.65) : Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(syncVM.isSyncing)
                if syncVM.isGmailConnected {
                    Button("Disconnect Gmail") {
                        GmailService.shared.signOut()
                        syncVM.refreshState()
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.red)
                }

                // MARK: - What We Detect
                VStack(alignment: .leading, spacing: 12) {

                    Text("What we detect")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    VStack(spacing: 0) {

                        DetectRow(
                            icon: "bolt.fill",
                            color: .yellow,
                            label: "Utility Bills",
                            detail: "Electricity, water, gas"
                        )

                        Divider().padding(.leading, 44)

                        DetectRow(
                            icon: "creditcard.fill",
                            color: .blue,
                            label: "Finance",
                            detail: "EMI, statements, cards"
                        )

                        Divider().padding(.leading, 44)

                        DetectRow(
                            icon: "shield.fill",
                            color: .green,
                            label: "Insurance",
                            detail: "Health, vehicle, life"
                        )

                        Divider().padding(.leading, 44)

                        DetectRow(
                            icon: "doc.text.fill",
                            color: .purple,
                            label: "Policies",
                            detail: "Renewals & policy notices"
                        )
                    }
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                // MARK: - Privacy Note
                Label("Only bill-related emails are processed securely to detect bills.", systemImage: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 20)
            }
            .padding(.horizontal, 20)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: syncVM.showSuccessBanner)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: syncVM.showError)
            .animation(.easeInOut(duration: 0.2), value: syncVM.isSyncing)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Email Sync")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            syncVM.refreshState()
        }
    }

    private func getRootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController
    }
}

// MARK: - BannerView

private struct BannerView: View {

    let icon: String
    let title: String
    let message: String
    let tint: Color

    var body: some View {
        HStack(spacing: 12) {

            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(tint)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(14)
        .background(tint.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(tint.opacity(0.20), lineWidth: 1)
        )
    }
}

// MARK: - StatCard

private struct StatCard: View {

    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {

            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - DetectRow

private struct DetectRow: View {

    let icon: String
    let color: Color
    let label: String
    let detail: String

    var body: some View {
        HStack(spacing: 12) {

            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    NavigationStack {
        EmailSyncView()
            .environment(AppViewModel())
    }
}
