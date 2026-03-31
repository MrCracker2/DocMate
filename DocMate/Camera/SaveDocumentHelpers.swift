import SwiftUI

// MARK: - View Mode
enum ViewMode { case icons, list }

// MARK: - Sort Order
enum SortOrder: String, CaseIterable {
    case name = "Name"
    case kind = "Kind"
    case date = "Date"
    case size = "Size"
    case tags = "Tags"
}
