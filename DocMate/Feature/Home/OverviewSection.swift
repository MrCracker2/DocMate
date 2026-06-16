//
//  OverviewSection.swift
//  DocMate
//
//  Created by Shashwat kumar on 16/06/26.
//

import SwiftUI

struct StatCard: View {

    var icon: String
    var title: String
    var count: Int
    var tint: Color

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [tint, tint.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("\(count)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Text(title.uppercased())
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [tint.opacity(0.08), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [tint.opacity(0.2), tint.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

struct OverviewSection: View {

    @Environment(AppViewModel.self) var viewModel

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overview")
                .font(.title3)
                .fontWeight(.bold)

            LazyVGrid(columns: columns, spacing: 16) {
                StatCard(
                    icon: "exclamationmark.circle",
                    title: "Overdue",
                    count: viewModel.overdueDocuments.count,
                    tint: .red
                )
                StatCard(
                    icon: "clock.badge.exclamationmark",
                    title: "Expiring Soon",
                    count: viewModel.expiringDocuments.count,
                    tint: .orange
                )
                StatCard(
                    icon: "doc.on.doc",
                    title: "All Documents",
                    count: viewModel.documents.count,
                    tint: .blue
                )
                StatCard(
                    icon: "pin.fill",
                    title: "Pinned",
                    count: viewModel.pinnedDocuments.count,
                    tint: .green
                )
            }
        }
    }
}

#Preview {
    OverviewSection()
        .environment(AppViewModel())
        .padding()
}
