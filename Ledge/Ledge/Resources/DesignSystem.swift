// DesignSystem.swift
import SwiftUI

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

// MARK: - Decimal Formatting
extension Decimal {
    func formatted(as style: NumberFormatter.Style = .currency,
                   locale: Locale = .init(identifier: "es_MX")) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = style
        formatter.locale = locale
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: self as NSDecimalNumber) ?? "$0.00"
    }
    
    var currencyString: String { formatted(as: .currency) }
    
    var percentString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 1
        return formatter.string(from: self as NSDecimalNumber) ?? "0%"
    }
}

// MARK: - Design Tokens
struct LedgeDesign {
    // Corner Radius
    static let cardRadius: CGFloat = 20
    static let sheetRadius: CGFloat = 24
    static let componentRadius: CGFloat = 12
    static let pillRadius: CGFloat = 100
    
    // Shadows
    static let cardShadow = ShadowStyle(radius: 16, x: 0, y: 8, opacity: 0.12)
    
    // Spacing
    static let pagePadding: CGFloat = 20
    static let sectionSpacing: CGFloat = 24
    static let itemSpacing: CGFloat = 12
    
    // Card presets
    static let cardGradients: [(hex1: String, hex2: String, name: String)] = [
        ("#007AFF", "#0047AB", "Azul océano"),
        ("#CC0000", "#FF4444", "Rojo Santander"),
        ("#1C1C1E", "#48484A", "Negro noche"),
        ("#B8860B", "#FFD700", "Oro clásico"),
        ("#2E7D32", "#66BB6A", "Verde esmeralda"),
        ("#6A1B9A", "#AB47BC", "Morado real"),
        ("#00838F", "#26C6DA", "Teal premium"),
        ("#E65100", "#FF8F00", "Naranja fuego")
    ]
}

struct ShadowStyle {
    let radius: CGFloat, x: CGFloat, y: CGFloat, opacity: Double
}

// MARK: - View Modifiers
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: LedgeDesign.componentRadius))
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
    
    func sectionPadding() -> some View {
        self.padding(.horizontal, LedgeDesign.pagePadding)
    }
}

// MARK: - Haptics
struct LedgeHaptics {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}

// MARK: - Reusable Components
struct SectionHeader: View {
    let title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.title3.bold())
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.subheadline)
            }
        }
        .padding(.horizontal, LedgeDesign.pagePadding)
    }
}

struct UtilizationBar: View {
    let value: Double // 0-100
    var height: CGFloat = 8
    
    private var barColor: Color {
        switch value {
        case ..<30: return .green
        case 30..<60: return .yellow
        case 60..<90: return .orange
        default: return .red
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 100)
                    .fill(Color(.systemFill))
                    .frame(height: height)
                RoundedRectangle(cornerRadius: 100)
                    .fill(barColor)
                    .frame(width: geo.size.width * min(value / 100.0, 1.0), height: height)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: value)
            }
        }
        .frame(height: height)
    }
}

struct StatCard: View {
    let label: String
    let value: String
    var valueColor: Color = .primary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            Text(value)
                .font(.title2.bold())
                .foregroundColor(valueColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .cardStyle()
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 52))
                .foregroundColor(Color(.tertiaryLabel))
            VStack(spacing: 6) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.top, 8)
            }
        }
        .padding(40)
    }
}
