//
//  NotificationSettingsView.swift
//  DocMate
//

import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {

    @State private var authStatus: UNAuthorizationStatus = .notDetermined
    @State private var expiryAlertsEnabled = true

    var body: some View {
        Form {

            // MARK: Permission Status
            Section {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(statusColor.opacity(0.12))
                            .frame(width: 46, height: 46)
                        Image(systemName: statusIcon)
                            .font(.title3)
                            .foregroundStyle(statusColor)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Notification Permission")
                            .fontWeight(.semibold)
                        Text(statusLabel)
                            .font(.caption)
                            .foregroundStyle(statusColor)
                    }
                    Spacer()
                    if authStatus == .denied {
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .font(.caption)
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.vertical, 4)
            }

            // MARK: Reminder Types
            Section("Reminders") {
                HStack {
                    Label("Expiry Reminders", systemImage: "calendar.badge.clock")
                    Spacer()
                    Text("30, 7 & 1 days before")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Label("Overdue Alerts", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Spacer()
                    Text("On due date")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // MARK: Info
            Section {
                Label("Notifications help you renew documents on time and never miss a payment deadline.", systemImage: "info.circle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .task { await fetchStatus() }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            Task { await fetchStatus() }
        }
    }

    // MARK: Helpers
    private var statusColor: Color {
        switch authStatus {
        case .authorized, .provisional: return .green
        case .denied: return .red
        default: return .secondary
        }
    }

    private var statusIcon: String {
        switch authStatus {
        case .authorized, .provisional: return "bell.fill"
        case .denied: return "bell.slash.fill"
        default: return "bell.badge"
        }
    }

    private var statusLabel: String {
        switch authStatus {
        case .authorized: return "Enabled"
        case .provisional: return "Provisional"
        case .denied: return "Disabled — tap 'Open Settings' to enable"
        case .notDetermined: return "Not requested yet"
        default: return "Unknown"
        }
    }

    private func fetchStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authStatus = settings.authorizationStatus
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
}
