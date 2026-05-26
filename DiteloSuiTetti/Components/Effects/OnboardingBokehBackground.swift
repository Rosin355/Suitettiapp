import SwiftUI

// MARK: - Theme

enum OnboardingBokehTheme {
    case cream, red, dark

    var usesScreenBlend: Bool { self == .dark }
}

// MARK: - Device tuning

private enum OnboardingBokehTuning {
    static let opacityMultiplier:  CGFloat = 1.45
    static let movementMultiplier: CGFloat = 1.65
    static let blurMultiplier:     CGFloat = 0.75
}

// MARK: - Config

private struct OnboardingBokehConfig: Identifiable {
    let id: Int
    let relX: CGFloat
    let relY: CGFloat
    let size: CGFloat
    let color: Color
    let opacity: CGFloat
    let blur: CGFloat
    let moveRelX: CGFloat
    let moveRelY: CGFloat
    let duration: Double
    let pulseDuration: Double
    let delay: Double
}

// MARK: - Per-theme circle configs

private let creamBokehConfigs: [OnboardingBokehConfig] = [
    OnboardingBokehConfig(id: 0, relX: 0.82, relY: 0.08, size: 220, color: .white,            opacity: 0.22, blur: 30, moveRelX: 0.06, moveRelY: 0.07, duration: 13, pulseDuration: 5.5, delay: 0.0),
    OnboardingBokehConfig(id: 1, relX: 0.12, relY: 0.40, size: 150, color: .brandYellowLight, opacity: 0.20, blur: 24, moveRelX: 0.06, moveRelY: 0.08, duration: 11, pulseDuration: 4.5, delay: 2.0),
    OnboardingBokehConfig(id: 2, relX: 0.65, relY: 0.75, size: 180, color: .white,            opacity: 0.18, blur: 28, moveRelX: 0.07, moveRelY: 0.06, duration: 15, pulseDuration: 5.0, delay: 1.0),
    OnboardingBokehConfig(id: 3, relX: 0.20, relY: 0.88, size: 200, color: .brandYellowLight, opacity: 0.16, blur: 26, moveRelX: 0.06, moveRelY: 0.05, duration: 12, pulseDuration: 4.5, delay: 3.0),
    OnboardingBokehConfig(id: 4, relX: 0.50, relY: 0.05, size: 130, color: .white,            opacity: 0.18, blur: 22, moveRelX: 0.05, moveRelY: 0.06, duration: 10, pulseDuration: 4.0, delay: 1.5),
]

private let redBokehConfigs: [OnboardingBokehConfig] = [
    OnboardingBokehConfig(id: 0, relX: 0.78, relY: 0.08, size: 220, color: .white,            opacity: 0.20, blur: 24, moveRelX: 0.07, moveRelY: 0.09, duration: 10, pulseDuration: 4.5, delay: 0.0),
    OnboardingBokehConfig(id: 1, relX: 0.08, relY: 0.52, size: 170, color: .brandYellowLight, opacity: 0.24, blur: 18, moveRelX: 0.08, moveRelY: 0.10, duration:  8, pulseDuration: 3.5, delay: 1.5),
    OnboardingBokehConfig(id: 2, relX: 0.55, relY: 0.75, size: 120, color: .white,            opacity: 0.20, blur: 14, moveRelX: 0.08, moveRelY: 0.09, duration:  7, pulseDuration: 3.0, delay: 3.0),
    OnboardingBokehConfig(id: 3, relX: 0.05, relY: 0.10, size: 290, color: .white,            opacity: 0.16, blur: 28, moveRelX: 0.09, moveRelY: 0.07, duration: 11, pulseDuration: 5.0, delay: 0.7),
    OnboardingBokehConfig(id: 4, relX: 0.65, relY: 0.55, size: 140, color: .brandYellow,      opacity: 0.20, blur: 14, moveRelX: 0.08, moveRelY: 0.09, duration:  9, pulseDuration: 4.0, delay: 2.2),
    OnboardingBokehConfig(id: 5, relX: 0.90, relY: 0.62, size: 320, color: .white,            opacity: 0.16, blur: 22, moveRelX: 0.08, moveRelY: 0.07, duration: 10, pulseDuration: 4.5, delay: 1.8),
    OnboardingBokehConfig(id: 6, relX: 0.28, relY: 0.85, size: 260, color: .brandYellowLight, opacity: 0.20, blur: 16, moveRelX: 0.09, moveRelY: 0.08, duration:  8, pulseDuration: 3.5, delay: 2.5),
]

private let darkBokehConfigs: [OnboardingBokehConfig] = [
    OnboardingBokehConfig(id: 0, relX: 0.80, relY: 0.08, size: 280, color: .brandYellowLight, opacity: 0.22, blur: 22, moveRelX: 0.07, moveRelY: 0.09, duration: 12, pulseDuration: 5.0, delay: 0.0),
    OnboardingBokehConfig(id: 1, relX: 0.12, relY: 0.72, size: 220, color: .brandRed,         opacity: 0.24, blur: 20, moveRelX: 0.08, moveRelY: 0.07, duration: 10, pulseDuration: 4.0, delay: 1.8),
    OnboardingBokehConfig(id: 2, relX: 0.42, relY: 0.06, size: 160, color: .white,            opacity: 0.18, blur: 18, moveRelX: 0.08, moveRelY: 0.08, duration:  9, pulseDuration: 3.5, delay: 3.0),
    OnboardingBokehConfig(id: 3, relX: 0.70, relY: 0.55, size: 190, color: .brandYellow,      opacity: 0.20, blur: 16, moveRelX: 0.09, moveRelY: 0.07, duration: 11, pulseDuration: 4.5, delay: 2.2),
    OnboardingBokehConfig(id: 4, relX: 0.05, relY: 0.18, size: 240, color: .white,            opacity: 0.16, blur: 24, moveRelX: 0.07, moveRelY: 0.09, duration: 14, pulseDuration: 5.5, delay: 0.7),
    OnboardingBokehConfig(id: 5, relX: 0.85, relY: 0.82, size: 200, color: .brandYellowLight, opacity: 0.22, blur: 18, moveRelX: 0.08, moveRelY: 0.08, duration:  8, pulseDuration: 3.5, delay: 2.5),
]

private func configs(for theme: OnboardingBokehTheme) -> [OnboardingBokehConfig] {
    switch theme {
    case .cream: return creamBokehConfigs
    case .red:   return redBokehConfigs
    case .dark:  return darkBokehConfigs
    }
}

// MARK: - Circle view

private struct OnboardingBokehCircleView: View {
    let config: OnboardingBokehConfig
    let baseX: CGFloat
    let baseY: CGFloat
    let moveX: CGFloat
    let moveY: CGFloat
    let opacity: CGFloat
    let debug: Bool

    @State private var animating = false
    @State private var pulsing   = false

    var body: some View {
        Circle()
            .fill(config.color.opacity(opacity * (pulsing ? 1.25 : 1.0)))
            .frame(width: config.size, height: config.size)
            .overlay {
                if debug {
                    Circle().strokeBorder(.yellow, lineWidth: 1.5)
                }
            }
            .blur(radius: config.blur * OnboardingBokehTuning.blurMultiplier)
            .offset(
                x: baseX + (animating ? moveX : 0),
                y: baseY + (animating ? moveY : 0)
            )
            .onAppear {
                withAnimation(
                    .easeInOut(duration: config.duration)
                        .repeatForever(autoreverses: true)
                        .delay(config.delay)
                ) { animating = true }

                withAnimation(
                    .easeInOut(duration: config.pulseDuration)
                        .repeatForever(autoreverses: true)
                        .delay(config.delay + config.pulseDuration * 0.4)
                ) { pulsing = true }
            }
    }
}

// MARK: - Background view

struct OnboardingBokehBackground: View {
    let theme: OnboardingBokehTheme
    static let debugMode = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack(alignment: .topLeading) {
                ForEach(configs(for: theme)) { config in
                    let baseX = config.relX * w - config.size / 2
                    let baseY = config.relY * h - config.size / 2

                    let effectiveOpacity = Self.debugMode
                        ? min(config.opacity * OnboardingBokehTuning.opacityMultiplier * 2.0, 1.0)
                        : config.opacity * OnboardingBokehTuning.opacityMultiplier

                    let moveMultiplier = Self.debugMode
                        ? OnboardingBokehTuning.movementMultiplier * 1.5
                        : OnboardingBokehTuning.movementMultiplier

                    let moveX = config.moveRelX * w * moveMultiplier
                    let moveY = config.moveRelY * h * moveMultiplier

                    if reduceMotion {
                        Circle()
                            .fill(config.color.opacity(effectiveOpacity))
                            .frame(width: config.size, height: config.size)
                            .blur(radius: config.blur * OnboardingBokehTuning.blurMultiplier)
                            .offset(x: baseX, y: baseY)
                    } else {
                        OnboardingBokehCircleView(
                            config: config,
                            baseX: baseX,
                            baseY: baseY,
                            moveX: moveX,
                            moveY: moveY,
                            opacity: effectiveOpacity,
                            debug: Self.debugMode
                        )
                    }
                }
            }
        }
        .blendMode(theme.usesScreenBlend ? .screen : .normal)
        .allowsHitTesting(false)
    }
}

// MARK: - Previews

#Preview("Cream theme") {
    ZStack {
        Color.brandCream.ignoresSafeArea()
        OnboardingBokehBackground(theme: .cream)
    }
}

#Preview("Red theme") {
    ZStack {
        Color.brandRed.ignoresSafeArea()
        OnboardingBokehBackground(theme: .red)
    }
}

#Preview("Dark theme") {
    ZStack {
        Color(red: 26/255, green: 26/255, blue: 26/255).ignoresSafeArea()
        OnboardingBokehBackground(theme: .dark)
    }
}

#Preview("Reduce Motion") {
    ZStack {
        Color.brandRed.ignoresSafeArea()
        OnboardingBokehBackground(theme: .red)
    }
}
