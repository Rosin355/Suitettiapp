import SwiftUI

extension View {
    func cardShadow() -> some View {
        self
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
            .shadow(color: .black.opacity(0.04), radius: 1, x: 0, y: 0.5)
    }
}
