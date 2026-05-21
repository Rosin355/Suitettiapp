import SwiftUI

struct HomeStatsStrip: View {
    private let stats: [(String, String)] = [
        ("100+", "Associazioni"),
        ("312", "Comitati"),
        ("16 giu", "3° Festival dell'umano tutto intero"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<stats.count, id: \.self) { i in
                if i > 0 {
                    Rectangle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 0.5, height: 28)
                }
                VStack(spacing: 3) {
                    Text(stats[i].0)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                        .kerning(-0.5)
                    Text(stats[i].1)
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.65))
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(stats[i].0) \(stats[i].1)")
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
        .background(.thinMaterial)
        .overlay(alignment: .top) {
            Rectangle().fill(.white.opacity(0.3)).frame(height: 0.5)
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(.brandRed.opacity(0.6)).frame(height: 0.5)
        }
    }
}
