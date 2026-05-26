import SwiftUI

// MARK: - Shimmer

private struct ShimmerModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = -0.5

    func body(content: Content) -> some View {
        if reduceMotion {
            content.opacity(0.5)
        } else {
            content
                .overlay {
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.45), .clear],
                        startPoint: .init(x: phase - 0.3, y: 0.5),
                        endPoint:   .init(x: phase + 0.3, y: 0.5)
                    )
                    .blendMode(.overlay)
                    .allowsHitTesting(false)
                }
                .onAppear {
                    withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                        phase = 1.5
                    }
                }
        }
    }
}

private extension View {
    func shimmer() -> some View { modifier(ShimmerModifier()) }
}

// MARK: - Skeleton block

private func skeletonBlock(width: CGFloat? = nil, height: CGFloat) -> some View {
    RoundedRectangle(cornerRadius: height / 2)
        .fill(Color.brandGrayLight.opacity(0.25))
        .frame(width: width, height: height)
}

// MARK: - Skeleton list row

struct SkeletonListRow: View {
    var isLast: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.brandGrayLight.opacity(0.25))
                    .frame(width: 58, height: 58)

                VStack(alignment: .leading, spacing: 8) {
                    skeletonBlock(width: 70, height: 14)
                    skeletonBlock(height: 14)
                    skeletonBlock(width: 110, height: 12)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)

            if !isLast {
                Divider().padding(.leading, 88)
            }
        }
    }
}

// MARK: - Skeleton featured card (196pt, matches FeaturedArticleCard)

struct SkeletonFeaturedCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RoundedRectangle(cornerRadius: 0)
                .fill(Color.brandGrayLight.opacity(0.25))
                .frame(height: 108)

            VStack(alignment: .leading, spacing: 8) {
                skeletonBlock(width: 60, height: 12)
                skeletonBlock(height: 14)
                skeletonBlock(width: 100, height: 12)
            }
            .padding(.horizontal, 13)
            .padding(.top, 11)
            .padding(.bottom, 14)
        }
        .frame(width: 196)
        .background(.white.opacity(0.82))
        .clipShape(.rect(cornerRadius: DT.cornerRadius))
        .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Skeleton loading list

struct SkeletonLoadingList: View {
    var count: Int = 5

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<count, id: \.self) { i in
                SkeletonListRow(isLast: i == count - 1)
            }
        }
        .background(.white.opacity(0.82))
        .clipShape(.rect(cornerRadius: DT.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: DT.cornerRadius)
                .strokeBorder(.white.opacity(0.75), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.06), radius: 7, x: 0, y: 2)
        .shimmer()
        .padding(.horizontal, DT.padding)
    }
}

// MARK: - Previews

#Preview("Skeleton list") {
    ZStack {
        Color.brandCream.ignoresSafeArea()
        SkeletonLoadingList()
            .padding(.top, 16)
    }
}

#Preview("Skeleton featured cards") {
    ZStack {
        Color.brandCream.ignoresSafeArea()
        HStack(spacing: 12) {
            SkeletonFeaturedCard()
            SkeletonFeaturedCard()
        }
        .padding(.horizontal, DT.padding)
    }
}
