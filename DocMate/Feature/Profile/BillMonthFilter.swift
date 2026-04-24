//
//  BillMonthFilter.swift
//  DocMate
//
//  Created by Naman Yadav on 24/04/26.
//


import Foundation

enum BillMonthFilter: Equatable {
    case thisMonth
    case lastMonth
    case twoMonthsAgo
    case custom(Date)

    var id: String {
        switch self {
        case .thisMonth:       return "thisMonth"
        case .lastMonth:       return "lastMonth"
        case .twoMonthsAgo:    return "twoMonthsAgo"
        case .custom(let d):   return "custom-\(d.timeIntervalSince1970)"
        }
    }

 
    var chipLabel: String {
        switch self {
        case .thisMonth:    return monthName(offsetBy: 0)
        case .lastMonth:    return monthName(offsetBy: -1)
        case .twoMonthsAgo: return monthName(offsetBy: -2)
        case .custom(let d):
            let f = DateFormatter()
            f.dateFormat = "MMM yyyy"
            return f.string(from: d)
        }
    }

    /// Full label for empty-state message
    var displayLabel: String { chipLabel }

    /// The reference date used for filtering
    var referenceDate: Date {
        let calendar = Calendar.current
        switch self {
        case .thisMonth:
            return Date()
        case .lastMonth:
            return calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        case .twoMonthsAgo:
            return calendar.date(byAdding: .month, value: -2, to: Date()) ?? Date()
        case .custom(let d):
            return d
        }
    }

    private func monthName(offsetBy offset: Int) -> String {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .month, value: offset, to: Date()) ?? Date()
        let f = DateFormatter()
        f.dateFormat = "MMM yyyy"
        return f.string(from: date)
    }

    static var presets: [BillMonthFilter] {
        [.thisMonth, .lastMonth, .twoMonthsAgo]
    }
}
