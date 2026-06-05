import SwiftUI

struct ArticlesFilterBar: View {
    @Binding var selectedCategory: String
    let categories: [String]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { cat in
                    let isOn = selectedCategory == cat
                    Button(cat) {
                        if reduceMotion {
                            selectedCategory = cat
                        } else {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                selectedCategory = cat
                            }
                        }
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isOn ? .white : .brandBlack)
                    .kerning(-0.2)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .background(
                        isOn
                            ? AnyShapeStyle(.brandBlack)
                            : AnyShapeStyle(.white.opacity(0.82))
                    )
                    .clipShape(Capsule())
                    .overlay {
                        if !isOn {
                            Capsule()
                                .strokeBorder(.black.opacity(0.09), lineWidth: 0.5)
                        }
                    }
                    .shadow(
                        color: .black.opacity(isOn ? 0.22 : 0.05),
                        radius: isOn ? 7 : 2, x: 0, y: isOn ? 2 : 1
                    )
                }
            }
            .padding(.horizontal, DT.padding)
        }
        .scrollIndicators(.hidden)
    }
}
