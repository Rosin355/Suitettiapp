import SwiftUI

/// Ambient editorial ticker — scrolls civic keywords at low opacity.
/// Purely solid background — no edge fading, no masking, no gradients.
/// Uses GeometryReader on the first copy to measure exact segment width
/// so the repeat loop is frame-perfect with no visible jump.
struct HeroTickerView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animOffset: CGFloat = 0

    private let duration: Double = 32
    private let segment = "DITELO SUI TETTI  ·  BENE COMUNE  ·  SUSSIDIARIETÀ  ·  LIBERTÀ EDUCATIVA  ·  VITA E FAMIGLIA  ·  "
    private let tickerRed = Color(red: 0.78, green: 0.04, blue: 0.10)

    var body: some View {
        tickerRed
            .frame(height: 34)
            .overlay(alignment: .leading) { tickerTrack }
            .clipped()
            .accessibilityHidden(true)
    }

    private var tickerTrack: some View {
        HStack(spacing: 0) {
            // First copy measured via GeometryReader for a seamless pixel-perfect loop
            Text(segment)
                .tickerStyle()
                .background {
                    GeometryReader { geo in
                        Color.clear.onAppear {
                            guard !reduceMotion else { return }
                            let w = geo.size.width
                            withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                                animOffset = -w
                            }
                        }
                    }
                }
            ForEach(1..<6, id: \.self) { _ in
                Text(segment).tickerStyle()
            }
        }
        .offset(x: animOffset)
    }
}

private extension Text {
    func tickerStyle() -> some View {
        self
            .font(.system(size: 10, weight: .semibold))
            .kerning(1.5)
            .foregroundStyle(.white.opacity(0.50))
            .fixedSize()
    }
}

#Preview {
    VStack(spacing: 0) {
        Color(red: 0.91, green: 0.10, blue: 0.17).frame(height: 80)
        HeroTickerView()
    }
}
