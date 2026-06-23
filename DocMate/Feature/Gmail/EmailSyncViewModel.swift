//
//  EmailSyncViewModel.swift
//  DocMate
//
//  Created by Shashwat kumar on 27/04/26.
//



import SwiftUI

@Observable
class EmailSyncViewModel {

    // MARK: - UI State

    var isSyncing = false
    var isGmailConnected = false
    var connectedEmail = ""

    var currentStep = ""

    var syncedCount = 0
    var skippedCount = 0

    var errorMessage = ""

    var showSuccessBanner = false
    var showError = false

    var lastSyncDate: Date?

    // MARK: - Refresh State

    func refreshState() {
        isGmailConnected = GmailService.shared.isSignedIn
        connectedEmail = GmailService.shared.connectedEmail ?? ""
    }

    // MARK: - Main Sync Action

    @MainActor
    func startSync(
        presenting viewController: UIViewController,
        appViewModel: AppViewModel
    ) async {

        guard !isSyncing else { return }

        isSyncing = true
        defer { isSyncing = false }

        // Reset UI State
        currentStep = "Connecting to Gmail..."

        syncedCount = 0
        skippedCount = 0

        errorMessage = ""

        showSuccessBanner = false
        showError = false

        do {
            // MARK: Gmail Login

            if !GmailService.shared.isSignedIn {
                try await GmailService.shared.signIn(
                    presenting: viewController
                )
            }

            isGmailConnected = true
            connectedEmail = GmailService.shared.connectedEmail ?? ""

            // MARK: Start Import

            currentStep = "Importing bills..."

            let beforeCount = appViewModel.allBills.count

            await appViewModel.syncBillsFromGmail()

            let afterCount = appViewModel.allBills.count

            syncedCount = max(afterCount - beforeCount, 0)

            currentStep = ""

            lastSyncDate = Date()

            if syncedCount > 0 {
                showSuccessBanner = true
            } else {
                errorMessage = "No new bills found."
                showError = true
            }

        } catch {

            currentStep = ""

            errorMessage = "Unable to sync bills. Please try again."

            showError = true
        }
    }
}
