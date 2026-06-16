//
//  ReviewDocumentView.swift
//  DocMateDummy
//

import SwiftUI

struct ReviewDocumentView: View {

    var viewModel: ScannerFlowViewModel
    @State private var manualDate: Date? = nil

    // MARK: - Body
    var body: some View {

        ScrollView {   // 
            VStack(spacing: 24) {

                // MARK: - Top Preview Card
                thumbnailSection

                // MARK: - Bottom Actions
                bottomSection
            }
            .padding()
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground)) //
        .navigationTitle("Review Document")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {

            // MARK: - Back
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    viewModel.goBack()
                } label: {
                    Image(systemName: "chevron.left")
                }
            }

            // MARK: - Skip
            ToolbarItem(placement: .topBarTrailing) {
                if showSkip {
                    Button("Skip") {
                        viewModel.skip()
                    }
                }
            }
        }
    }

    // MARK: - Show Skip?
    private var showSkip: Bool {
        switch viewModel.phase {
        case .reviewing, .detectingExpiry:
            return true
        default:
            return false
        }
    }

    // MARK: - Preview Card (TOP SECTION)
    private var thumbnailSection: some View {
        HStack(spacing: 16) {

            // Image
            if let image = viewModel.scannedImages.first {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 110, height: 150)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 4)
            }

            // Status Info
            VStack(alignment: .leading, spacing: 8) {

                Text("Document Preview")
                    .font(.headline)

                switch viewModel.phase {

                case .reviewing:
                    Text("Ready to extract expiry date")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                case .detectingExpiry:
                    Label("Scanning document...", systemImage: "clock")
                        .foregroundStyle(.secondary)

                case .expiryResult(let date):
                    Label("Date detected", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)

                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.title3)
                        .fontWeight(.semibold)

                case .noDateFound:

                    if let manualDate {

                        //  SHOW SELECTED DATE (LIVE UPDATE)
                        Label("Selected date", systemImage: "calendar")
                            .foregroundStyle(.blue)

                        Text(manualDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.title3)
                            .fontWeight(.semibold)

                    } else {

                        //  BEFORE SELECTION
                        Label("No date detected", systemImage: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    }

                case .scanning:
                    EmptyView()
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Bottom Section (ACTIONS)
    @ViewBuilder
    private var bottomSection: some View {

        switch viewModel.phase {

        // MARK: Detect Button
        case .reviewing:
            primaryButton(
                title: "Detect Expiry Date",
                icon: "calendar.badge.clock"
            ) {
                viewModel.detectExpiryDate()
            }

        // MARK: Loading
        case .detectingExpiry:
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.5)

                Text("Running OCR...")
                    .foregroundStyle(.secondary)

                Text("Searching for dates...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))

        // MARK: Date Found
        case .expiryResult(let date):
            VStack(spacing: 16) {

                DatePicker(
                    "Expiry Date",
                    selection: Binding(
                        get: { date },
                        set: { viewModel.confirmDate($0) }
                    ),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)

                primaryButton(title: "Confirm") {
                    viewModel.confirmDate(date)
                }
            }

        // MARK: No Date Found (BEST UX VERSION)
        case .noDateFound:
            VStack(spacing: 16) {

                Text("Couldn't detect expiry date")
                    .font(.headline)

                Text("Please select it manually to continue")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                // STEP 1: Button first
                if manualDate == nil {

                    Button {
                        withAnimation {
                            manualDate = Date()
                        }
                    } label: {
                        Label("Select Date", systemImage: "calendar")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                } else {

                    // STEP 2: Show picker
                    DatePicker(
                        "Select Date",
                        selection: Binding(
                            get: { manualDate ?? Date() },
                            set: { manualDate = $0 }
                        ),
                        in: Date()...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                }

                // STEP 3: Confirm
                Button {
                    if let date = manualDate {
                        viewModel.confirmDate(date)
                    }
                } label: {
                    Text("Confirm")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(manualDate == nil ? Color.gray : Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(manualDate == nil)
            }

        case .scanning:
            EmptyView()
        }
    }

    // MARK: - Reusable Button
    private func primaryButton(
        title: String,
        icon: String? = nil,
        action: @escaping () -> Void
    ) -> some View {

        Button(action: action) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}
