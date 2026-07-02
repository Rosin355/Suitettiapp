import SwiftUI

/// Reusable dark promo card for the Home feed — a spotlight for a campaign, festival,
/// or announcement. Generic on its copy/action so the component itself never goes
/// stale: only the strings passed in are time-bound. The whole card is a single large
/// (≥44pt) tap target with a combined accessibility label.
struct HomePromoCard: View {
    let eyebrow: String
    let title: String
    var chipColor: Color = .brandYellow
    var accessibilityHintText: String = "Apre i contenuti nel visualizzatore in-app"
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    CategoryChip(
                        text: eyebrow,
                        color: chipColor,
                        background: chipColor.opacity(0.18)
                    )
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .kerning(-0.4)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                Image(systemName: "arrow.right")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.brandRed)
                    .clipShape(.rect(cornerRadius: 12))
                    .shadow(color: .brandRed.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .padding(18)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [.brandBlack, Color(red: 37/255, green: 37/255, blue: 37/255)],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .clipShape(.rect(cornerRadius: DT.cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: DT.cornerRadius)
                    .strokeBorder(.white.opacity(0.08), lineWidth: 0.5)
            }
            .cardShadow()
        }
        .buttonStyle(PressableCardStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(eyebrow): \(title)")
        .accessibilityHint(accessibilityHintText)
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    ZStack {
        Color.brandCream.ignoresSafeArea()
        HomePromoCard(
            eyebrow: "SPECIALE",
            title: "3° Festival — rivivi video e materiali",
            action: {}
        )
        .padding()
    }
}
