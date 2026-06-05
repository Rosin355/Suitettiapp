import SwiftUI
import StoreKit

struct RateAppSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview

    @State private var reviewed = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            iconBlock
                .padding(.bottom, 28)

            titleBlock
                .padding(.bottom, 16)

            bodyBlock
                .padding(.bottom, 0)

            Spacer()

            buttonsBlock
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
        }
        .background(.brandCream)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(.brandCream)
        .sensoryFeedback(.success, trigger: reviewed) { _, new in new }
    }

    // MARK: - Sub-views

    private var iconBlock: some View {
        ZStack {
            Circle()
                .fill(.brandRed.opacity(0.10))
                .frame(width: 90, height: 90)
            Circle()
                .fill(.brandRed.opacity(0.06))
                .frame(width: 110, height: 110)
            Image(systemName: "megaphone.fill")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(.brandRed)
        }
    }

    private var titleBlock: some View {
        Text("Ti sta piacendo l'app?")
            .font(.system(size: 22, weight: .bold))
            .foregroundStyle(.brandBlack)
            .kerning(-0.4)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 28)
    }

    private var bodyBlock: some View {
        Text("Una recensione ci aiuta a far crescere Ditelo sui Tetti e a portare più lontano questa voce civica. Bastano pochi secondi, ma per noi contano molto.")
            .font(.system(size: 15))
            .foregroundStyle(.brandBlack.opacity(0.65))
            .lineSpacing(4)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 28)
    }

    private var buttonsBlock: some View {
        VStack(spacing: 10) {
            Button {
                reviewed = true
                requestReview()
                Task {
                    try? await Task.sleep(for: .milliseconds(700))
                    dismiss()
                }
            } label: {
                Text("Valuta l'app")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(.brandRed)
                    .clipShape(.rect(cornerRadius: DT.smallCorner))
                    .shadow(color: .brandRed.opacity(0.35), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Valuta l'app sull'App Store")

            Button {
                dismiss()
            } label: {
                Text("Più tardi")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.brandGray)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Rimanda la valutazione")
        }
    }
}

// MARK: - Preview

#Preview {
    RateAppSheet()
}
