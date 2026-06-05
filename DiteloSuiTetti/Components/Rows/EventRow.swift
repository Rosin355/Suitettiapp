import SwiftUI

struct EventRow: View {
    let day: String
    let month: String
    let title: String
    let place: String
    var isLast: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                VStack(spacing: 2) {
                    Text(day)
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(.brandRed)
                    Text(month)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.brandRed)
                        .kerning(0.5)
                }
                .frame(width: 44)
                .padding(.vertical, 7)
                .background(.brandRed.opacity(0.1))
                .clipShape(.rect(cornerRadius: 12))
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.brandBlack)
                    Text(place)
                        .font(.system(size: 13))
                        .foregroundStyle(.brandGray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(day) \(month). \(title). \(place).")

            if !isLast {
                Divider().padding(.leading, 74)
            }
        }
    }
}
