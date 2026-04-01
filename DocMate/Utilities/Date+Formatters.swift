import Foundation

extension Date {

    /// "Mar 31, 2026"
    var mediumFormatted: String {
        Date.mediumFormatter.string(from: self)
    }

    /// "31/03/26"
    var shortFormatted: String {
        Date.shortFormatter.string(from: self)
    }

    // Static instances created once, reused everywhere — avoids per-render allocations.
    private static let mediumFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    private static let shortFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd/MM/yy"
        return f
    }()
}
