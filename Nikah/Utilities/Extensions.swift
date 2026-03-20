// Utilities/Extensions.swift

import SwiftUI
import Foundation

// MARK: - Date Extensions
extension Date {
    var age: Int {
        Calendar.current.dateComponents([.year], from: self, to: Date()).year ?? 0
    }

    var formattedShort: String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .none
        return fmt.string(from: self)
    }

    var timeAgoDisplay: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

// MARK: - String Extensions
extension String {
    var isValidEmail: Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: self.trimmingCharacters(in: .whitespaces))
    }

    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - View Extensions
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    func cardStyle() -> some View {
        self
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 4)
    }

    func nikahButton(color: Color = AppColors.green) -> some View {
        self
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(color)
            .cornerRadius(14)
    }

    func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

// MARK: - Color Extensions
extension Color {
    static let nikahGreen = Color(red: 0.13, green: 0.55, blue: 0.13)
    static let nikahGold = Color(red: 0.85, green: 0.65, blue: 0.13)
    static let nikahBackground = Color(.systemGroupedBackground)
}

// MARK: - Double Extensions
extension Double {
    var heightFormatted: String {
        String(format: "%.2f", self) + " ft"
    }
}

// MARK: - Array Extension
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
