//
//  EmailSyncView.swift
//  DocMate
//
//  Apple Native iOS Style
//

import SwiftUI

struct EmailSyncView: View {
    
    @State private var syncVM = EmailSyncViewModel()
    @Environment(AppViewModel.self) private var appViewModel
    
    var body: some View {
        Form {
            
            // MARK: Gmail Status
            Section {
                HStack(spacing: 14) {
                    
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.12))
                            .frame(width: 46, height: 46)
                        
                        Image(systemName: "envelope.badge.fill")
                            .font(.title3)
                            .foregroundStyle(.blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Gmail Sync")
                            .fontWeight(.semibold)
                        
                        Text(syncVM.isGmailConnected ? "Connected" : "Not Connected")
                            .font(.caption)
                            .foregroundStyle(
                                syncVM.isGmailConnected ? .green : .secondary
                            )
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 4)
            }
            
            
            // MARK: Last Sync
            if let last = syncVM.lastSyncDate {
                Section("Last Sync") {
                    Text(last.formatted(date: .abbreviated, time: .shortened))
                }
            }
            
            
            // MARK: Bills Stats
            if syncVM.syncedCount > 0 || syncVM.skippedCount > 0 {
                Section("Bills Summary") {
                    
                    HStack {
                        Label("Imported", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        
                        Spacer()
                        
                        Text("\(syncVM.syncedCount)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Label("Skipped", systemImage: "arrow.uturn.backward.circle")
                            .foregroundStyle(.orange)
                        
                        Spacer()
                        
                        Text("\(syncVM.skippedCount)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            
            // MARK: Actions
            Section("Actions") {
                
                Button {
                    Task {
                        guard let vc = getRootViewController() else { return }
                        
                        await syncVM.startSync(
                            presenting: vc,
                            appViewModel: appViewModel
                        )
                    }
                } label: {
                    
                    HStack {
                        if syncVM.isSyncing {
                            ProgressView()
                            Text("Syncing...")
                        } else {
                            Label(
                                syncVM.isGmailConnected
                                ? "Sync Again"
                                : "Connect Gmail",
                                systemImage: syncVM.isGmailConnected
                                ? "arrow.triangle.2.circlepath"
                                : "link"
                            )
                        }
                        
                        Spacer()
                    }
                }
                .disabled(syncVM.isSyncing)
                
                
                if syncVM.isGmailConnected {
                    Button(role: .destructive) {
                        GmailService.shared.signOut()
                        syncVM.refreshState()
                    } label: {
                        Label("Disconnect Gmail", systemImage: "trash")
                    }
                }
            }
            
            
            // MARK: What We Detect
            Section("What We Detect") {
                
                detectRow(
                    icon: "bolt.fill",
                    title: "Utility Bills",
                    subtitle: "Electricity, water, gas",
                    color: .yellow
                )
                
                detectRow(
                    icon: "creditcard.fill",
                    title: "Finance",
                    subtitle: "EMI, statements, cards",
                    color: .blue
                )
                
                detectRow(
                    icon: "shield.fill",
                    title: "Insurance",
                    subtitle: "Health, vehicle, life",
                    color: .green
                )
                
                detectRow(
                    icon: "doc.text.fill",
                    title: "Policies",
                    subtitle: "Renewals & notices",
                    color: .purple
                )
            }
            
            
            // MARK: Privacy
            Section("Privacy") {
                
                VStack(alignment: .leading, spacing: 10) {
                    
                    Label(
                        "We only scan read-only emails from the last 30 days.",
                        systemImage: "calendar.badge.clock"
                    )
                    
                    Label(
                        "Only bill-related emails are checked to detect bills.",
                        systemImage: "doc.text.magnifyingglass"
                    )
                    
                    Label(
                        "We cannot send, delete, or edit your Gmail emails.",
                        systemImage: "lock.fill"
                    )
                    
                    Label(
                        "Your data is processed securely inside DocMate.",
                        systemImage: "checkmark.shield.fill"
                    )
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Email Sync")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            syncVM.refreshState()
        }
    }
}


// MARK: Helpers

extension EmailSyncView {
    
    @ViewBuilder
    func detectRow(
        icon: String,
        title: String,
        subtitle: String,
        color: Color
    ) -> some View {
        
        HStack(spacing: 12) {
            
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
    
    
    func getRootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController
    }
}


// MARK: Preview

#Preview {
    NavigationStack {
        EmailSyncView()
            .environment(AppViewModel())
    }
}
