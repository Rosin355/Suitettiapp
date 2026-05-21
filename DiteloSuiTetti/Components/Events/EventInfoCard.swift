import SwiftUI

/// A single card row showing one piece of event info (date, location, etc.).
/// If `action` is provided the row is tappable — a chevron indicates this.
struct EventInfoCard: View {
    let icon: String
    let heading: String
    let primaryLine: String
    var secondaryLine: String = ""
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.brandRed.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.brandRed)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(heading.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.brandGray)
                    .kerning(0.5)
                Text(primaryLine)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.brandBlack)
                if !secondaryLine.isEmpty {
                    Text(secondaryLine)
                        .font(.system(size: 13))
                        .foregroundStyle(.brandGray)
                }
            }

            Spacer(minLength: 0)

            if action != nil {
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.brandGrayLight)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .onTapGesture { action?() }
    }
}
