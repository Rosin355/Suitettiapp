import SwiftUI

/// Animated mesh-gradient background for the home hero.
/// Uses MeshGradient (iOS 18+) for GPU-native, blur-free warmth.
/// Animation is driven by a single phase float so SwiftUI only
/// re-evaluates the mesh points — no separate blur layers.
struct HeroBackgroundView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = 0

    var body: some View {
        MeshGradient(
            width: 3, height: 3,
            points: meshPoints,
            colors: Self.colors,
            background: Color(red: 0.80, green: 0.05, blue: 0.12)
        )
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 24).repeatForever(autoreverses: true)) {
                phase = 1
            }
        }
    }

    // Very subtle mesh deformation — max ~5% displacement
    private var meshPoints: [SIMD2<Float>] {
        let p = Float(phase)
        let a = p * 0.052   // horizontal drift
        let b = p * 0.038   // vertical drift
        return [
            [0,               0],  [0.5,          0],  [1,             0],
            [0,       0.5 + b],    [0.5 + a, 0.5 - b], [1,    0.5 + a * 0.5],
            [0,               1],  [0.5 - a * 0.3, 1], [1,             1],
        ]
    }

    // Editorial warm-red palette. Values stay close to brandRed
    // (232,25,44) so variation is felt rather than seen.
    static let colors: [Color] = [
        Color(red: 0.88, green: 0.06, blue: 0.13),   // TL — dark crimson
        Color(red: 0.95, green: 0.14, blue: 0.22),   // TC — brand red
        Color(red: 0.84, green: 0.07, blue: 0.13),   // TR — deep
        Color(red: 0.78, green: 0.05, blue: 0.11),   // ML — deep crimson
        Color(red: 0.91, green: 0.10, blue: 0.17),   // MC — brand red
        Color(red: 0.96, green: 0.26, blue: 0.22),   // MR — warm coral
        Color(red: 0.82, green: 0.06, blue: 0.13),   // BL — deep
        Color(red: 0.90, green: 0.15, blue: 0.22),   // BC — warm red
        Color(red: 0.85, green: 0.08, blue: 0.14),   // BR — mid-dark
    ]
}

#Preview {
    HeroBackgroundView()
        .frame(height: 420)
        .clipped()
}
