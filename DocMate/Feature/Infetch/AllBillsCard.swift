//
//  AllBillsCard.swift
//  DocMate
//

import SwiftUI

struct AllBillsCard: View {

    let doc: Infetch
    var onMarkPaid: () -> Void

    @State private var isUpdating = false

    private var isPaid: Bool {
        doc.isPaid
    }

    var body: some View {

        HStack(alignment: .center, spacing: 14) {

            // MARK: Left Content
            VStack(alignment: .leading, spacing: 6) {

                Text(doc.subjectName)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(doc.name)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 8) {

                    if let amount = doc.amount {
                        Text("₹\(amount, specifier: "%.0f")")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }

                    Text("•")
                        .foregroundStyle(.secondary)

                    Text("Due \(doc.dueDate, style: .date)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // MARK: Right Action
            if isPaid {

                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Paid")
                }
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.green)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.12))
                .clipShape(Capsule())

            } else {

                Button {
                    guard !isUpdating else { return }

                    isUpdating = true

                    Task {
                        onMarkPaid()

                        try? await Task.sleep(for: .milliseconds(500))

                        isUpdating = false
                    }

                } label: {

                    HStack(spacing: 6) {

                        if isUpdating {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.white)
                        } else {
                            Image(systemName: "checkmark")
                        }

                        Text(isUpdating ? "Updating..." : "Mark Paid")
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(Color.blue)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(isUpdating)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
        .contentShape(Rectangle())
    }
}
