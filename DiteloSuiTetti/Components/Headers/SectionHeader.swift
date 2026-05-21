import SwiftUI

struct SectionHeader: View {
    let title: String
    var action: String? = nil
    var onAction: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(.brandBlack)
            Spacer()
            if let action, let onAction {
                Button(action, action: onAction)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.brandRed)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 10)
    }
}
