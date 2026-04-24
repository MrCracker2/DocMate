//
//  BillMonthFilter.swift
//  DocMate
//
//  Created by Naman Yadav on 24/04/26.
//


//
//  BillMonthFilter.swift
//  DocMate
//

import Foundation

/// Month filter used in BillsHistoryView.
enum BillMonthFilter: String, CaseIterable, Identifiable {
    case thisMonth = "This Month"
    case lastMonth = "Last Month"

    var id: String { rawValue }

    /// Human-readable label that includes the actual month name.
    var displayLabel: String {
        let calendar = Calendar.current
        let now = Date()
        switch self {
        case .thisMonth:
            return monthName(for: now, calendar: calendar)
        case .lastMonth:
            let last = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            return monthName(for: last, calendar: calendar)
        }
    }

    private func monthName(for date: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: date)
    }
}