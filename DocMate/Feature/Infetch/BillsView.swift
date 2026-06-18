//
//  BillsView.swift
//  DocMate
//
//  Dedicated "Bills" tab — spending insights, upcoming bills,
//  email sync and bills history all in one place.
//

import SwiftUI
import Charts

struct BillsView: View {

    @Environment(AppViewModel.self) var viewModel
    @State private var isGmailConnected = GmailService.shared.isSignedIn

    // MARK: - Derived Data

    private var paidBills: [Infetch] { viewModel.billHistory }
    private var unpaidBills: [Infetch] { viewModel.inFetch }

    private var spentThisMonth: Double {
        let cal = Calendar.current
        return paidBills.reduce(0) { sum, bill in
            guard let paidAt = bill.paidAt,
                  cal.isDate(paidAt, equalTo: Date(), toGranularity: .month)
            else { return sum }
            return sum + (bill.amount ?? 0)
        }
    }

    private var upcomingTotal: Double {
        unpaidBills
            .filter { $0.dueDate >= Date() }
            .reduce(0) { $0 + ($1.amount ?? 0) }
    }

    private var unpaidCount: Int { unpaidBills.count }

    private var overdueCount: Int {
        unpaidBills.filter { $0.dueDate < Date() }.count
    }

    /// Last 6 months of total paid spending, oldest → newest.
    private var monthlySpending: [MonthlySpend] {
        let cal = Calendar.current
        let now = Date()
        return (0..<6).reversed().compactMap { offset -> MonthlySpend? in
            guard let monthDate = cal.date(byAdding: .month, value: -offset, to: now)
            else { return nil }
            let total = paidBills.reduce(0.0) { sum, bill in
                guard let paidAt = bill.paidAt,
                      cal.isDate(paidAt, equalTo: monthDate, toGranularity: .month)
                else { return sum }
                return sum + (bill.amount ?? 0)
            }
            return MonthlySpend(month: monthDate, total: total)
        }
    }

    private var categorySpending: [CategorySpend] {
        InfetchCategory.allCases.compactMap { category in
            let total = paidBills
                .filter { $0.inFetchCategory == category }
                .reduce(0.0) { $0 + ($1.amount ?? 0) }
            return total > 0 ? CategorySpend(category: category, total: total) : nil
        }
    }

    private var hasSpending: Bool {
        monthlySpending.contains { $0.total > 0 }
    }

    // MARK: - Body

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {

                if viewModel.allBills.isEmpty {
                    emptyState
                        .padding(.top, 100)
                } else {
                    spendHeroCard

                    // Upcoming bills — moved up, right under the hero
                    if !unpaidBills.isEmpty {
                        YourBillsSection(bills: unpaidBills)
                    }

                    monthlyChartSection
                    categorySection
                    quickActionsSection
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Bills")
        .onAppear {
            isGmailConnected = GmailService.shared.isSignedIn
        }
    }

    // MARK: - Spend Hero Card

    private var spendHeroCard: some View {
        VStack(alignment: .leading, spacing: 20) {

            HStack {
                Label("This Month", systemImage: "calendar")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
                Image(systemName: "indianrupeesign.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.85))
            }

            Text("₹\(Int(spentThisMonth))")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            HStack(spacing: 0) {
                heroStat(value: "₹\(Int(upcomingTotal))", label: "Upcoming")
                heroDivider
                heroStat(value: "\(unpaidCount)", label: "Unpaid")
                heroDivider
                heroStat(value: "\(overdueCount)", label: "Overdue")
            }
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(.white.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.blue, Color.indigo],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Color.blue.opacity(0.25), radius: 14, y: 8)
    }

    private func heroStat(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
    }

    private var heroDivider: some View {
        Rectangle()
            .fill(.white.opacity(0.25))
            .frame(width: 1, height: 28)
    }

    // MARK: - Monthly Spending Chart

    private var monthlyChartSection: some View {
        cardSection(title: "Monthly Spending", subtitle: "Last 6 months") {
            if hasSpending {
                Chart(monthlySpending) { item in
                    BarMark(
                        x: .value("Month", item.month, unit: .month),
                        y: .value("Spent", item.total)
                    )
                    .foregroundStyle(Color.blue.gradient)
                    .cornerRadius(8)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { _ in
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                    }
                }
                .frame(height: 200)
            } else {
                placeholder("No spending recorded yet")
            }
        }
    }

    // MARK: - Category Breakdown

    private var categorySection: some View {
        cardSection(title: "By Category", subtitle: "Where it goes") {
            if categorySpending.isEmpty {
                placeholder("No category data yet")
            } else {
                Chart(categorySpending) { item in
                    SectorMark(
                        angle: .value("Spent", item.total),
                        innerRadius: .ratio(0.62),
                        angularInset: 2
                    )
                    .cornerRadius(6)
                    .foregroundStyle(by: .value("Category", item.category.rawValue))
                }
                .frame(height: 220)
                .chartLegend(position: .bottom, spacing: 14)
            }
        }
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Manage", subtitle: nil)

            VStack(spacing: 0) {
                NavigationLink(destination: EmailSyncView()) {
                    actionRow(
                        icon: "envelope.badge.fill",
                        title: "Email Sync",
                        subtitle: isGmailConnected ? "Connected" : "Not connected",
                        tint: .blue
                    )
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 64)

                NavigationLink(destination: BillsHistoryView()) {
                    actionRow(
                        icon: "clock.arrow.circlepath",
                        title: "Bills History",
                        subtitle: "View paid bills",
                        tint: .green
                    )
                }
                .buttonStyle(.plain)
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    // MARK: - Reusable Card / Header

    @ViewBuilder
    private func cardSection<Content: View>(
        title: String,
        subtitle: String?,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: title, subtitle: subtitle)
            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }

    private func sectionHeader(title: String, subtitle: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.title3.weight(.bold))
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func actionRow(
        icon: String,
        title: String,
        subtitle: String,
        tint: Color
    ) -> some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(tint.opacity(0.15))
                .frame(width: 38, height: 38)
                .overlay(
                    Image(systemName: icon)
                        .font(.body)
                        .foregroundStyle(tint)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private func placeholder(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: 120)
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        if isGmailConnected {
            connectedEmptyState
        } else {
            firstTimeState
        }
    }

    private var firstTimeState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 92, height: 92)
                Image(systemName: "envelope.badge.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.blue)
            }

            Text("Track Bills Automatically")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text("Connect Gmail and DocMate will detect your bills, due dates and spending — no manual entry needed.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            NavigationLink(destination: EmailSyncView()) {
                Label("Connect Gmail", systemImage: "link")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 32)
            .padding(.top, 4)

            Text("Read-only • last 30 days • we never edit your inbox")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private var connectedEmptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.shield")
                .font(.system(size: 44))
                .foregroundStyle(.green)

            Text("No Bills Found Yet")
                .font(.title2.bold())

            Text("Gmail is connected. Run a sync to scan your recent emails for bills.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            NavigationLink(destination: EmailSyncView()) {
                Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Chart Models

private struct MonthlySpend: Identifiable {
    let id = UUID()
    let month: Date
    let total: Double
}

private struct CategorySpend: Identifiable {
    var id: String { category.rawValue }
    let category: InfetchCategory
    let total: Double
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BillsView()
            .environment(AppViewModel())
            .environment(AuthViewModel())
    }
}
