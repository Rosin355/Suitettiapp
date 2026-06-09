import SwiftUI

struct SupportActionsSection: View {
    let ways: [(icon: String, title: String, detail: String)]

    var body: some View {
        VStack(spacing: 0) {
            SectionHeader(title: "Come puoi aiutare")

            VStack(spacing: 8) {
                ForEach(0..<ways.count, id: \.self) { i in
                    WayCard(way: ways[i])
                }
            }
            .padding(.horizontal, DT.padding)
            .padding(.bottom, 12)

            CopyLinkButton()
                .padding(.horizontal, DT.padding)
                .padding(.bottom, 10)

            SocialShareRow()
                .padding(.horizontal, DT.padding)
                .padding(.bottom, 8)
        }
    }
}

private struct WayCard: View {
    let way: (icon: String, title: String, detail: String)

    var body: some View {
        GCard {
            HStack(alignment: .top, spacing: 14) {
                Text(way.icon)
                    .font(.system(size: 18))
                    .frame(width: 40, height: 40)
                    .background(.brandRed.opacity(0.06))
                    .clipShape(.rect(cornerRadius: 12))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text(way.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.brandBlack)
                        .kerning(-0.3)
                    Text(way.detail)
                        .font(.system(size: 13))
                        .foregroundStyle(.brandGray)
                        .lineSpacing(3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }
}

private struct CopyLinkButton: View {
    @State private var copied = false

    var body: some View {
        Button {
            // Canonical public domain — never share the legacy comitaticivici.it domain.
            UIPasteboard.general.string = AppEnvironment.publicWebsiteURL.absoluteString
            withAnimation(.easeInOut(duration: 0.2)) { copied = true }
            Task {
                try? await Task.sleep(for: .seconds(2))
                withAnimation(.easeInOut(duration: 0.2)) { copied = false }
            }
        } label: {
            Text(copied ? "✓ Link copiato!" : "🔗 Copia link sito")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(copied ? .white : .brandBlack)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(copied ? AnyShapeStyle(.brandRed) : AnyShapeStyle(.white.opacity(0.82)))
                .clipShape(.rect(cornerRadius: DT.smallCorner))
                .overlay {
                    RoundedRectangle(cornerRadius: DT.smallCorner)
                        .strokeBorder(.black.opacity(0.06), lineWidth: 0.5)
                }
                .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                .animation(.easeInOut(duration: 0.2), value: copied)
        }
        .sensoryFeedback(.impact(weight: .light, intensity: 0.8), trigger: copied) { _, new in new }
    }
}

private struct SocialShareRow: View {
    var body: some View {
        HStack(spacing: 10) {
            SocialButton(label: "W", name: "WhatsApp",
                         background: AnyShapeStyle(Color(red: 37/255, green: 211/255, blue: 102/255)))
            SocialButton(label: "Ig", name: "Instagram",
                         background: AnyShapeStyle(LinearGradient(
                            colors: [Color(red: 240/255, green: 148/255, blue: 51/255),
                                     Color(red: 220/255, green: 39/255, blue: 67/255),
                                     Color(red: 188/255, green: 24/255, blue: 136/255)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                         )))
            SocialButton(label: "f", name: "Facebook",
                         background: AnyShapeStyle(Color(red: 24/255, green: 119/255, blue: 242/255)))
            SocialButton(label: "T", name: "Telegram",
                         background: AnyShapeStyle(Color(red: 38/255, green: 165/255, blue: 228/255)))
        }
    }
}

private struct SocialButton: View {
    let label: String
    let name: String
    let background: AnyShapeStyle

    var body: some View {
        Button {} label: {
            VStack(spacing: 3) {
                Text(label)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                Text(name)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(background)
            .clipShape(.rect(cornerRadius: DT.smallCorner))
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .accessibilityLabel("Condividi su \(name)")
    }
}
