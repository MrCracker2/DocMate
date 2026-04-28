//
//  BillsHistoryView.swift
//  DocMate
//
//  Created by Naman Yadav on 06/04/26.
//



import SwiftUI

struct BillsHistoryView: View {

    @Environment(AppViewModel.self) var viewModel
    @State private var showCustomPicker = false
    @State private var customPickerDate = Date()
    @State private var activeMonthOffset: Int? = nil
    @State private var customMonth: Date? = nil
    @State private var selectedCategory: InfetchCategory? = nil
    @State private var selectedBill: Infetch? = nil

    // MARK: - Helpers

    private var monthsToShow: [Date] {
        let cal = Calendar.current
        return (0..<3).compactMap { cal.date(byAdding: .month, value: -$0, to: Date()) }
    }

    private var activeMonths: [Date] {
        if let offset = activeMonthOffset {
            let cal = Calendar.current
            if let d = cal.date(byAdding: .month, value: -offset, to: Date()) { return [d] }
        }
        if let custom = customMonth { return [custom] }
        return monthsToShow
    }

    private func billsForMonth(_ month: Date) -> [Infetch] {
        let cal = Calendar.current
        return viewModel.billHistory.filter {
            guard let paidAt = $0.paidAt else { return false }
            return cal.isDate(paidAt, equalTo: month, toGranularity: .month)

        }
    }

    private func billsForMonth(_ month: Date, category: InfetchCategory) -> [Infetch] {
        billsForMonth(month).filter { $0.inFetchCatgogry == category }.sorted { $0.dueDate > $1.dueDate }
    }

    private func visibleBillsForMonth(_ month: Date) -> [Infetch] {
        if let cat = selectedCategory {
            return billsForMonth(month).filter { $0.inFetchCatgogry == cat }
        }
        return billsForMonth(month)
    }

    private func monthLabel(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"; return f.string(from: date)
    }

    private func shortMonthLabel(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMM yyyy"; return f.string(from: date)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // Category filter chips
                categoryChips
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                // Month sections
                ForEach(activeMonths, id: \.self) { month in
                    monthSection(for: month)
                }

                Spacer().frame(height: 40)
            }
        }
        .navigationTitle("Bills History")
        .navigationBarTitleDisplayMode(.large)
        .background(Color(.systemGroupedBackground))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { menuButton }
        }
        .sheet(isPresented: $showCustomPicker) { customMonthSheet }
        .animation(.easeInOut(duration: 0.22), value: activeMonthOffset)
        .animation(.easeInOut(duration: 0.22), value: customMonth)
        .animation(.easeInOut(duration: 0.22), value: selectedCategory)
        .sheet(item: $selectedBill) { bill in
            BillSheetView(doc: bill)
                .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Category Chips

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryChip(title: "All", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(InfetchCategory.allCases) { cat in
                    CategoryChip(title: cat.rawValue, isSelected: selectedCategory == cat) {
                        selectedCategory = cat
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - 3-dot Menu

    private var menuButton: some View {
        Menu {
            Button {
                activeMonthOffset = nil
                customMonth = nil
            } label: {
                Label("Last 3 Months", systemImage: "calendar")
            }

            Divider()

            Button {
                showCustomPicker = true
            } label: {
                Label("Custom Month…", systemImage: "slider.horizontal.3")
            }
        } label: {
            Image(systemName: "ellipsis").font(.system(size: 17))
        }
    }

    // MARK: - Month Section

    @ViewBuilder
    private func monthSection(for month: Date) -> some View {
        let bills = visibleBillsForMonth(month)
        if !bills.isEmpty {
            VStack(alignment: .leading, spacing: 0) {

                // Month title only — no total amount
                Text(monthLabel(month))
                    .font(.title3)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                // Category subsections — no category label header
                ForEach(InfetchCategory.allCases) { category in
                    if selectedCategory == nil || selectedCategory == category {
                        let catBills = billsForMonth(month, category: category)
                        if !catBills.isEmpty {
                            VStack(spacing: 8) {
                                ForEach(catBills) { bill in
                                    HistoryBillCard(bill: bill)
                                        .onTapGesture { selectedBill = bill }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 12)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Custom Month Sheet

    private var customMonthSheet: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DatePicker("Select month", selection: $customPickerDate, in: ...Date(), displayedComponents: [.date])
                    .datePickerStyle(.graphical)
                    .padding(.horizontal)
                    .padding(.top, 8)
                Spacer()
            }
            .navigationTitle("Select Month")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showCustomPicker = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Apply") {
                        customMonth = customPickerDate
                        activeMonthOffset = nil
                        showCustomPicker = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(24)
    }
}

// MARK: - HistoryBillCard (matches AllBillsCard style)

struct HistoryBillCard: View {

    let bill: Infetch

    // HistoryBillCard mein
    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "d MMM, h:mm a"
        let dateToShow = bill.paidAt ?? bill.dueDate  
        return f.string(from: dateToShow)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(bill.subjectName)
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Text(bill.name)
                    .font(.headline)

                if let amount = bill.amount {
                    Text("₹\(amount, specifier: "%.0f")")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("Paid")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.blue.opacity(0.15))
                    .foregroundStyle(Color.blue)
                    .clipShape(Capsule())

                Text(formattedDate)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(14)
        .shadow(radius: 2)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BillsHistoryView()
    }
    .environment(AppViewModel())
    .environment(AuthViewModel())
}
