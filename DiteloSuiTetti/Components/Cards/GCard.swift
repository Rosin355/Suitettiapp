import SwiftUI

struct GCard<Content: View>: View {
    let tint: Color
    let action: (() -> Void)?
    let content: Content

    init(tint: Color = .white.opacity(0.82),
         action: (() -> Void)? = nil,
         @ViewBuilder content: () -> Content) {
        self.tint = tint
        self.action = action
        self.content = content()
    }

    var body: some View {
        Group {
            if let action {
                Button(action: action) { cardBody }
                    .buttonStyle(.plain)
            } else {
                cardBody
            }
        }
    }

    private var cardBody: some View {
        content
            .background(tint)
            .clipShape(.rect(cornerRadius: DT.cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: DT.cornerRadius)
                    .strokeBorder(.white.opacity(0.7), lineWidth: 0.5)
            }
            .cardShadow()
    }
}
