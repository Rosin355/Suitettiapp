import SwiftUI

private struct StatItem {
    let value: String
    let label: String
}

/// Refined stats strip that sits at the bottom of the home hero.
/// Avoids blur materials — uses a transparent dark gradient overlay
/// on top of the mesh gradient background for zero extra compositing cost.
struct HeroStatsView: View {
    private let stats: [StatItem] = [
        StatItem(value: "100+",  label: "Associazioni"),
        StatItem(value: "312",   label: "Comitati"),
        StatItem(value: "16 giu", label: "3° Festival"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(stats.enumerated()), id: \.offset) { index, stat in
                if index > 0 {
                    Rectangle()
                        .fill(.white.opacity(0.16))
                        .frame(width: 0.5, height: 32)
                }
                statCell(stat)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .background {
            LinearGradient(
                colors: [.black.opacity(0), .black.opacity(0.24)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .overlay(alignment: .top) {
            Rectangle().fill(.white.opacity(0.10)).frame(height: 0.5)
        }
    }

    private func statCell(_ stat: StatItem) -> some View {
        VStack(spacing: 3) {
            Text(stat.value)
                .font(.system(size: 21, weight: .bold))
                .foregroundStyle(.white)
                .kerning(-0.5)
            Text(stat.label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.56))
                .kerning(0.2)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(stat.value) \(stat.label)")
    }
}

#Preview {
    ZStack {
        Color(red: 0.91, green: 0.10, blue: 0.17)
        VStack {
            Spacer()
            HeroStatsView()
        }
    }
    .frame(height: 200)
}
