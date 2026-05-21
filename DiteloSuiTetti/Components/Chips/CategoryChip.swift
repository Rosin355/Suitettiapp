import SwiftUI

struct CategoryChip: View {
    let text: String
    var color: Color = .brandRed
    var background: Color? = nil

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .kerning(0.3)
            .foregroundStyle(color)
            .padding(.horizontal, 11)
            .padding(.vertical, 4)
            .background(background ?? color.opacity(0.14))
            .clipShape(Capsule())
    }
}
