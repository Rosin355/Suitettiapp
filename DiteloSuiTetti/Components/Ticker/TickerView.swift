import SwiftUI

struct TickerView: View {
    @State private var isAnimating = false
    private let segment = "DITELO SUI TETTI ☆  BENE COMUNE ♡  SUSSIDIARIETÀ ☆  LIBERTÀ EDUCATIVA ♡  VITA E FAMIGLIA ☆  "

    var body: some View {
        Color.brandRed
            .frame(height: 40)
            .overlay(alignment: .leading) {
                HStack(spacing: 0) {
                    ForEach(0..<4, id: \.self) { _ in
                        Text(segment)
                            .font(.system(size: 11, weight: .bold))
                            .kerning(1.2)
                            .foregroundStyle(.white)
                            .fixedSize()
                    }
                }
                .offset(x: isAnimating ? -1300 : 0)
                .animation(.linear(duration: 22).repeatForever(autoreverses: false), value: isAnimating)
            }
            .clipped()
            .onAppear { isAnimating = true }
            .accessibilityHidden(true)
    }
}
