import SwiftUI

// MARK: - Config

private struct BokehConfig: Identifiable {
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
    let delay: Double
}

private let bokehConfigs: [BokehConfig] = [
    BokehConfig(id: 0, relX: 0.78, relY: 0.08, size: 200, color: .white,            opacity: 0.18, blur: 26, moveRelX: 0.06, moveRelY: 0.08, duration: 14, delay: 0),
    BokehConfig(id: 1, relX: 0.08, relY: 0.52, size: 160, color: .brandYellowLight, opacity: 0.22, blur: 18, moveRelX: 0.05, moveRelY: 0.07, duration: 11, delay: 1.5),
    BokehConfig(id: 2, relX: 0.55, relY: 0.75, size: 110, color: .white,            opacity: 0.15, blur: 14, moveRelX: 0.04, moveRelY: 0.06, duration: 9,  delay: 3.0),
    BokehConfig(id: 3, relX: 0.05, relY: 0.10, size: 240, color: .white,            opacity: 0.13, blur: 30, moveRelX: 0.07, moveRelY: 0.05, duration: 16, delay: 0.7),
    BokehConfig(id: 4, relX: 0.65, relY: 0.55, size: 130, color: .brandYellow,      opacity: 0.17, blur: 14, moveRelX: 0.05, moveRelY: 0.07, duration: 12, delay: 2.2),
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

    var body: some View {
        Circle()
            .fill(config.color.opacity(opacity))
            .frame(width: config.size, height: config.size)
            .overlay {
                if debug {
                    Circle().strokeBorder(.yellow, lineWidth: 1)
                }
            }
            .blur(radius: config.blur)
            .offset(
                x: baseX + (animating ? moveX : 0),
                y: baseY + (animating ? moveY : 0)
            )
            .animation(
                .easeInOut(duration: config.duration)
                    .repeatForever(autoreverses: true)
                    .delay(config.delay),
                value: animating
            )
            .onAppear { animating = true }
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
                    let moveX = config.moveRelX * w
                    let moveY = config.moveRelY * h
                    let effectiveOpacity = Self.debugMode ? min(config.opacity * 2.5, 1.0) : config.opacity
                    let effectiveMoveX = Self.debugMode ? moveX * 2 : moveX
                    let effectiveMoveY = Self.debugMode ? moveY * 2 : moveY

                    if reduceMotion {
                        Circle()
                            .fill(config.color.opacity(effectiveOpacity))
                            .frame(width: config.size, height: config.size)
                            .blur(radius: config.blur)
                            .offset(x: baseX, y: baseY)
                    } else {
                        BokehCircleView(
                            config: config,
                            baseX: baseX,
                            baseY: baseY,
                            moveX: effectiveMoveX,
                            moveY: effectiveMoveY,
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

#Preview("Debug mode") {
    ZStack(alignment: .topLeading) {
        Color.brandRed.ignoresSafeArea()
        BokehCirclesBackground()
    }
    .frame(height: 300)
}

#Preview("Reduce Motion") {
    ZStack(alignment: .topLeading) {
        Color.brandRed.ignoresSafeArea()
        BokehCirclesBackground()
    }
    .frame(height: 300)
}
