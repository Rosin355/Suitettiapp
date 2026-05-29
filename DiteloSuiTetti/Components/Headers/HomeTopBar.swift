import SwiftUI

struct HomeTopBar: View {
    @Binding var selectedTab: AppTab
    var scrolledPastHero: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                if scrolledPastHero {
                    Text("Ditelo sui Tetti")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.brandBlack)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                Spacer()
                sostieniciButton
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 10)
            .safeAreaPadding(.top)
        }
        .frame(maxWidth: .infinity)
        .background {
            if scrolledPastHero {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(.separator).frame(height: 0.5)
                    }
                    .ignoresSafeArea(edges: .top)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: scrolledPastHero)
    }

    private var sostieniciButton: some View {
        Button {
            selectedTab = .chiSiamo
        } label: {
            Text("Sostienici →")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(scrolledPastHero ? .brandBlack : .white)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
        }
        .glassEffect(.regular.interactive(), in: .capsule)
        .accessibilityLabel("Sostieni la rete civica")
    }
}
