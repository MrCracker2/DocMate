//
//  AllBillsView.swift
//  DocMate
//

import SwiftUI

struct AllBillsView: View {

    @Environment(AppViewModel.self) private var viewModel

    @State private var selectedCategory: InfetchCategory? = nil
    @State private var selectedBill: Infetch?

    @State private var showPaidToast = false
    @State private var toastBillName = ""

    var body: some View {

        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {

                // MARK: Category Filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {

                        CategoryChip(
                            title: "All",
                            isSelected: selectedCategory == nil
                        ) {
                            selectedCategory = nil
                        }

                        ForEach(InfetchCategory.allCases) { category in
                            CategoryChip(
                                title: category.rawValue,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }

                // MARK: Content
                if filteredBills.isEmpty {

                    emptyState

                } else {

                    LazyVStack(spacing: 14) {
                        ForEach(filteredBills) { bill in

                            AllBillsCard(doc: bill) {
                                markAsPaid(bill)
                            }
                            .onTapGesture {
                                selectedBill = bill
                            }
                            .transition(
                                .move(edge: .bottom)
                                .combined(with: .opacity)
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.top, 14)
            .padding(.bottom, 28)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("All Bills")
        .navigationBarTitleDisplayMode(.inline)

        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    EmailSyncView()
                } label: {
                    Image(systemName: "envelope.badge")
                }
            }
        }

        .sheet(item: $selectedBill) { bill in
            BillSheetView(doc: bill)
                .presentationDetents([.medium, .large])
        }

        .overlay(alignment: .bottom) {
            if showPaidToast {
                PaidToastView(billName: toastBillName)
                    .padding(.bottom, 14)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }

        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: filteredBills.count)
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: showPaidToast)
    }

    // MARK: Empty State

    private var emptyState: some View {
        VStack(spacing: 14) {

            Image(systemName: "tray")
                .font(.system(size: 42))
                .foregroundStyle(.secondary)

            Text("No Bills Found")
                .font(.headline)

            Text("Connect Gmail to automatically import your bills.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            NavigationLink {
                EmailSyncView()
            } label: {
                Text("Sync Gmail")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            .padding(.top, 4)
        }
        .padding(.top, 80)
        .padding(.horizontal, 30)
    }

    // MARK: Mark Paid

    private func markAsPaid(_ bill: Infetch) {

        Task {
            await viewModel.toggleBillStatus(bill)
        }

        toastBillName = bill.name

        withAnimation {
            showPaidToast = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation {
                showPaidToast = false
            }
        }
    }

    // MARK: Bills Source

    private var baseBills: [Infetch] {
        viewModel.inFetch.sorted {
            if $0.isPaid != $1.isPaid {
                return !$0.isPaid
            }
            return $0.dueDate < $1.dueDate
        }
    }

    // MARK: Filtered Bills

    private var filteredBills: [Infetch] {

        guard let selectedCategory else {
            return baseBills
        }

        return baseBills.filter {
            $0.inFetchCategory == selectedCategory
        }
    }
}

// MARK: CategoryChip

struct CategoryChip: View {
    
    var title: String
    var isSelected: Bool
    var onTap: () -> Void
    
    var body: some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(.medium)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
            .onTapGesture { onTap() }
    }
}

// MARK: PaidToastView

struct PaidToastView: View {

    let billName: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(.green)

            VStack(alignment: .leading, spacing: 1) {
                Text("Bill Paid!")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("\(billName) added to Bills History")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color(.separator).opacity(0.3), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        .padding(.horizontal, 16)
    }
}

#Preview {
    NavigationStack {
        AllBillsView()
            .environment(AppViewModel())
    }
}
