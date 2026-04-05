//
//  ReviewDocumentView.swift
//  DocMateDummy
//

import SwiftUI

struct ReviewDocumentView: View {

    @Environment(\.dismiss) private var dismiss
    var viewModel: ScannerFlowViewModel

    @State private var manualDate: Date = Date()

    // MARK: - Body
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {

                // MARK: - Document Thumbnail
                thumbnailSection

                Spacer()

                // MARK: - Bottom Section changes based on phase
                bottomSection

                Spacer()
            }
            .padding()
            .navigationTitle("Review Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }

                // Skip only shows during reviewing and detectingExpiry
                ToolbarItem(placement: .topBarTrailing) {
                    if showSkip {
                        Button("Skip") {
                            viewModel.skip()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Show Skip?
    private var showSkip: Bool {
        switch viewModel.phase {
        case .reviewing, .detectingExpiry: return true
        default: return false
        }
    }

    // MARK: - Thumbnail Section
    private var thumbnailSection: some View {
        HStack(spacing: 16) {

            // Document thumbnail
            if let image = viewModel.scannedImages.first {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(radius: 4)
            }

            // Right side — changes based on phase
            VStack(alignment: .leading, spacing: 8) {
                switch viewModel.phase {

                case .reviewing:
                    Text("Ready to extract date from document")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                case .detectingExpiry:
                    Text("Scanning document...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                case .expiryResult(let date):
                    Label("Date detected", systemImage: "checkmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.green)

                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.title3)
                        .fontWeight(.bold)

                case .noDateFound:
                    Label("No date found", systemImage: "xmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.red)

                case .scanning, .saving:
                    EmptyView()
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Bottom Section
    @ViewBuilder
    private var bottomSection: some View {
        switch viewModel.phase {

        // MARK: State 1 — Detect button
        case .reviewing:
            Button {
                viewModel.detectExpiryDate()
            } label: {
                Label("Detect Expiry Date", systemImage: "calendar.badge.clock")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

        // MARK: State 2 — OCR Loading
        case .detectingExpiry:
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.5)

                Text("Running OCR...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("Searching for dates...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

        // MARK: State 3 — Date Found → Confirm
        case .expiryResult(let date):
            VStack(spacing: 16) {

                // Editable date picker
                DatePicker(
                    "Expiry Date",
                    selection: Binding(
                        get: { date },
                        set: { viewModel.confirmDate($0) }   // updates if user edits
                    ),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)

                Button {
                    viewModel.confirmDate(date)
                } label: {
                    Text("Confirm")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

        // MARK: State 4 — No Date Found → Manual Picker
        case .noDateFound:
            VStack(spacing: 16) {

                Text("No expiry date found. Pick manually:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                DatePicker(
                    "Select Date",
                    selection: $manualDate,
                    in: Date()...,              // future dates only
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)

                Button {
                    viewModel.confirmDate(manualDate)
                } label: {
                    Text("Confirm")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

        case .scanning, .saving:
            EmptyView()
        }
    }
}
