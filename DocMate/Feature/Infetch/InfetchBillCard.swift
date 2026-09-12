import SwiftUI

extension InfetchCategory {
    var themeColor: Color {
        switch self {
        case .bill: return .blue
        case .finance: return .green
        case .insurance: return .purple
        case .policy: return .orange
        case .other: return .secondary
        }
    }
    
    var sfSymbol: String {
        switch self {
        case .bill: return "bolt.fill"
        case .finance: return "creditcard.fill"
        case .insurance: return "shield.fill"
        case .policy: return "doc.text.fill"
        case .other: return "questionmark.circle.fill"
        }
    }
}

struct InfetchBillCard: View {
    
    let doc: Infetch
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                // Biller details
                VStack(alignment: .leading, spacing: 2) {
                    Text(doc.name)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(doc.subjectName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Category Badge
                HStack(spacing: 4) {
                    Image(systemName: doc.inFetchCategory.sfSymbol)
                        .font(.system(size: 10, weight: .bold))
                    Text(doc.inFetchCategory.rawValue.uppercased())
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundColor(doc.inFetchCategory.themeColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(doc.inFetchCategory.themeColor.opacity(0.12))
                )
            }
            .padding(.bottom, 12)
            
            HStack(alignment: .firstTextBaseline) {
                if let amount = doc.amount {
                    Text("₹\(amount, specifier: "%.0f")")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 11))
                    Text("Due \(doc.dueDate, style: .date)")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(doc.dueDate < Date() ? .red : .secondary)
            }
            
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 120, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            doc.inFetchCategory.themeColor.opacity(0.25),
                            doc.inFetchCategory.themeColor.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

