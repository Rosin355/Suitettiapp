import SwiftUI

struct AppearModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    var delay: Double = 0

    func body(content: Content) -> some View {
        content
            .opacity(appeared || reduceMotion ? 1 : 0)
            .offset(y: appeared || reduceMotion ? 0 : 12)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeOut(duration: 0.35).delay(delay)) {
                    appeared = true
                }
            }
    }
}

extension View {
    func appearAnimation(delay: Double = 0) -> some View {
        modifier(AppearModifier(delay: delay))
    }
}
