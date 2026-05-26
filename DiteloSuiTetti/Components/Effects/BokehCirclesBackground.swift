import SwiftUI

// MARK: - Device tuning constants

private enum BokehTuning {
    static let opacityMultiplier:  CGFloat = 1.45
    static let movementMultiplier: CGFloat = 1.65
    static let blurMultiplier:     CGFloat = 0.75
}

// MARK: - Config

private struct BokehConfig: Identifiable {
    let id: Int
    let relX: CGFloat        // circle centre X as fraction of view width
    let relY: CGFloat        // circle centre Y as fraction of view height
    let size: CGFloat        // diameter in pt
    let color: Color
    let opacity: CGFloat     // base opacity (before BokehTuning.opacityMultiplier)
    let blur: CGFloat        // base blur radius (before BokehTuning.blurMultiplier)
    let moveRelX: CGFloat    // movement amplitude as fraction of view width
    let moveRelY: CGFloat    // movement amplitude as fraction of view height
    let duration: Double     // position animation duration in seconds
    let pulseDuration: Double // opacity pulse duration in seconds
    let delay: Double        // initial delay in seconds
}

private let bokehConfigs: [BokehConfig] = [
    BokehConfig(id: 0, relX: 0.78, relY: 0.08, size: 200, color: .white,            opacity: 0.20, blur: 26, moveRelX: 0.07, moveRelY: 0.09, duration: 10, pulseDuration: 4.5, delay: 0.0),
    BokehConfig(id: 1, relX: 0.08, relY: 0.52, size: 160, color: .brandYellowLight, opacity: 0.24, blur: 18, moveRelX: 0.08, moveRelY: 0.10, duration:  8, pulseDuration: 3.5, delay: 1.5),
    BokehConfig(id: 2, relX: 0.55, relY: 0.75, size: 110, color: .white,            opacity: 0.18, blur: 14, moveRelX: 0.08, moveRelY: 0.09, duration:  7, pulseDuration: 3.0, delay: 3.0),
    BokehConfig(id: 3, relX: 0.05, relY: 0.10, size: 280, color: .white,            opacity: 0.16, blur: 28, moveRelX: 0.09, moveRelY: 0.07, duration: 11, pulseDuration: 5.0, delay: 0.7),
    BokehConfig(id: 4, relX: 0.65, relY: 0.55, size: 130, color: .brandYellow,      opacity: 0.20, blur: 14, moveRelX: 0.08, moveRelY: 0.09, duration:  9, pulseDuration: 4.0, delay: 2.2),
    BokehConfig(id: 5, relX: 0.88, relY: 0.62, size: 320, color: .white,            opacity: 0.17, blur: 22, moveRelX: 0.08, moveRelY: 0.07, duration: 10, pulseDuration: 4.5, delay: 1.8),
    BokehConfig(id: 6, relX: 0.28, relY: 0.82, size: 260, color: .brandYellowLight, opacity: 0.20, blur: 16, moveRelX: 0.09, moveRelY: 0.08, duration:  8, pulseDuration: 3.5, delay: 2.5),
]

// MARK: - Circle view

private struct BokehCircleView: View {
    let config: BokehConfig
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
            .blur(radius: config.blur * BokehTuning.blurMultiplier)
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

struct BokehCirclesBackground: View {
    static let debugMode = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack(alignment: .topLeading) {
                ForEach(bokehConfigs) { config in
                    let baseX = config.relX * w - config.size / 2
                    let baseY = config.relY * h - config.size / 2

                    let effectiveOpacity = Self.debugMode
                        ? min(config.opacity * BokehTuning.opacityMultiplier * 2.0, 1.0)
                        : config.opacity * BokehTuning.opacityMultiplier

                    let moveMultiplier = Self.debugMode
                        ? BokehTuning.movementMultiplier * 1.5
                        : BokehTuning.movementMultiplier

                    let moveX = config.moveRelX * w * moveMultiplier
                    let moveY = config.moveRelY * h * moveMultiplier

                    if reduceMotion {
                        Circle()
                            .fill(config.color.opacity(effectiveOpacity))
                            .frame(width: config.size, height: config.size)
                            .blur(radius: config.blur * BokehTuning.blurMultiplier)
                            .offset(x: baseX, y: baseY)
                    } else {
                        BokehCircleView(
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
        .allowsHitTesting(false)
    }
}

// MARK: - Previews

#Preview("Normal") {
    ZStack(alignment: .topLeading) {
        Color.brandRed.ignoresSafeArea()
        BokehCirclesBackground()
    }
    .frame(height: 300)
}

#Preview("Device — Strong") {
    ZStack(alignment: .topLeading) {
        Color.brandRed.ignoresSafeArea()
        BokehCirclesBackground()
    }
    .frame(height: 480)
}

#Preview("Debug") {
    ZStack(alignment: .topLeading) {
        Color.brandRed.ignoresSafeArea()
        BokehCirclesBackground()
    }
    .frame(height: 480)
}

#Preview("Reduce Motion") {
    ZStack(alignment: .topLeading) {
        Color.brandRed.ignoresSafeArea()
        BokehCirclesBackground()
    }
    .frame(height: 300)
}
