//
//  BillsHistoryView.swift
//  DocMate
//
//  Created for the Paid Bills History feature.
//  Architecture: SwiftUI + @Observable AppViewModel via .environment(...)
//

import SwiftUI

// MARK: - BillsHistoryView

struct BillsHistoryView: View {

    @Environment(AppViewModel.self) var viewModel
    @State private var selectedFilter: BillMonthFilter = .thisMonth

    // MARK: - Computed (kept outside body per architecture rules)

    /// Bills filtered by the selected month, sorted latest-first.
    private var filteredBills: [Infetch] {
        viewModel.billsFiltered(by: selectedFilter)
            .sorted { $0.dueDate > $1.dueDate }
    }

    /// Bills grouped by start-of-day, preserving sorted order.
    private var groupedBills: [(key: Date, bills: [Infetch])] {
        let calendar = Calendar.current
        let dict = Dictionary(grouping: filteredBills) {
            calendar.startOfDay(for: $0.dueDate)
        }
        return dict
            .map { (key: $0.key, bills: $0.value) }
            .sorted { $0.key > $1.key }
    }

    private var totalSpend: Double {
        viewModel.totalSpend(for: selectedFilter)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // Month filter chips
                filterChips
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                // Total spend card
                totalSpendCard
                    .padding(.horizontal)
                    .padding(.bottom, 20)

                // Timeline or empty state
                if groupedBills.isEmpty {
                    emptyState
                        .padding(.top, 60)
                        .frame(maxWidth: .infinity)
                } else {
                    timelineContent
                        .padding(.horizontal)
                }
            }
        }
        .navigationTitle("Bills History")
        .navigationBarTitleDisplayMode(.large)
        .background(Color(.systemGroupedBackground))
        .animation(.easeInOut(duration: 0.25), value: selectedFilter)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: groupedBills.map(\.key))
    }

    // MARK: - Filter Chips

    private var filterChips: some View {
        HStack(spacing: 10) {
            ForEach(BillMonthFilter.allCases) { filter in
                Button {
                    selectedFilter = filter
                } label: {
                    Text(filter.displayLabel)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(
                            selectedFilter == filter
                                ? Color.blue
                                : Color(.secondarySystemGroupedBackground)
                        )
                        .foregroundStyle(selectedFilter == filter ? .white : .primary)
                        .clipShape(Capsule())
                        .shadow(
                            color: selectedFilter == filter ? Color.blue.opacity(0.3) : .clear,
                            radius: 6, x: 0, y: 3
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Total Spend Card

    private var totalSpendCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Total Paid")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .kerning(0.5)

                Text("₹\(totalSpend, specifier: "%.0f")")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }

            Spacer()

            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 50, height: 50)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.green)
            }
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    // MARK: - Timeline Content

    private var timelineContent: some View {
        LazyVStack(alignment: .leading, spacing: 0, pinnedViews: []) {
            ForEach(groupedBills, id: \.key) { group in
                // Section date header
                dateSectionHeader(for: group.key)
                    .padding(.bottom, 8)

                // Timeline rows
                ForEach(Array(group.bills.enumerated()), id: \.element.id) { index, bill in
                    TimelineRow(
                        bill: bill,
                        isLast: index == group.bills.count - 1
                    )
                }

                Spacer().frame(height: 20)
            }
        }
        .padding(.bottom, 40)
    }

    // MARK: - Date Section Header

    private func dateSectionHeader(for date: Date) -> some View {
        Text(sectionTitle(for: date))
            .font(.footnote)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .kerning(0.6)
            .padding(.top, 4)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.08))
                    .frame(width: 80, height: 80)
                Image(systemName: "tray.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(Color.blue.opacity(0.5))
            }

            Text("No bills found")
                .font(.headline)
                .foregroundStyle(.primary)

            Text("Paid bills for \(selectedFilter.displayLabel) will appear here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    // MARK: - Helpers

    private func sectionTitle(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date)     { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }

        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - TimelineRow

struct TimelineRow: View {

    let bill: Infetch
    let isLast: Bool

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "d MMM, h:mm a"
        return f.string(from: bill.dueDate)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {

            // Timeline column
            timelineColumn

            // Card
            billCard
                .padding(.leading, 12)
                .padding(.bottom, isLast ? 0 : 12)
        }
    }

    // MARK: - Timeline Column

    private var timelineColumn: some View {
        VStack(spacing: 0) {
            // Dot
            ZStack {
                Circle()
                    .fill(Color.green)
                    .frame(width: 12, height: 12)
                Circle()
                    .fill(Color.white)
                    .frame(width: 5, height: 5)
            }
            .padding(.top, 16)

            // Vertical line (only if not last row)
            if !isLast {
                Rectangle()
                    .fill(Color.green.opacity(0.25))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
        }
        .frame(width: 20)
    }

    // MARK: - Bill Card

    private var billCard: some View {
        HStack(spacing: 12) {

            // Category icon
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(bill.inFetchCatgogry.iconColor.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: bill.inFetchCatgogry.sfSymbol)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(bill.inFetchCatgogry.iconColor)
            }

            // Bill details
            VStack(alignment: .leading, spacing: 3) {
                Text(bill.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                Text(bill.SubjectName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Amount + date
            VStack(alignment: .trailing, spacing: 3) {
                if let amount = bill.amount {
                    Text("₹\(amount, specifier: "%.0f")")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                }

                Text(formattedDate)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BillsHistoryView()
    }
    .environment(AppViewModel())
}