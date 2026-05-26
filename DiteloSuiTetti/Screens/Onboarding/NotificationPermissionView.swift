import SwiftUI

// MARK: - Permission pre-prompt (shown between onboarding and ContentView)

struct NotificationPermissionView: View {
    let onAllow: () -> Void
    let onSkip:  () -> Void

    private let features: [(icon: String, color: Color, title: String, detail: String)] = [
        (
            "doc.text.fill", .brandRed,
            "Nuovi articoli",
            "Ricevi un avviso quando esce un nuovo approfondimento."
        ),
        (
            "calendar",
            Color(red: 42/255, green: 122/255, blue: 75/255),
            "Eventi",
            "Non perdere incontri, festival e appuntamenti pubblici."
        ),
        (
            "folder.fill",
            Color(red: 91/255, green: 82/255, blue: 208/255),
            "Documenti",
            "Scopri subito nuovi materiali e pubblicazioni."
        ),
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.brandCream, .white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Bell icon badge
                        ZStack {
                            Circle()
                                .fill(Color.brandRed.opacity(0.10))
                                .frame(width: 84, height: 84)
                            Image(systemName: "bell.badge.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(Color.brandRed)
                        }
                        .safeAreaPadding(.top)
                        .padding(.top, 32)
                        .padding(.bottom, 28)
                        .accessibilityHidden(true)

                        // Title
                        Text("Rimani aggiornato")
                            .font(.system(size: 34, weight: .black))
                            .kerning(-1.2)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.brandBlack)
                            .padding(.bottom, 14)

                        // Subtitle
                        Text("Ti avviseremo quando saranno pubblicati nuovi articoli, eventi e documenti.")
                            .font(.system(size: 16))
                            .foregroundStyle(.brandGray)
                            .multilineTextAlignment(.center)
                            .lineSpacing(5)
                            .frame(maxWidth: 300)
                            .padding(.bottom, 36)

                        // Feature cards
                        VStack(spacing: 10) {
                            ForEach(features.indices, id: \.self) { i in
                                NotificationFeatureCard(
                                    icon:   features[i].icon,
                                    color:  features[i].color,
                                    title:  features[i].title,
                                    detail: features[i].detail
                                )
                            }
                        }
                        .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 24)
                }

                // CTAs pinned at bottom
                VStack(spacing: 4) {
                    Button(action: onAllow) {
                        Text("Abilita notifiche")
                            .font(.system(size: 17, weight: .bold))
                            .kerning(-0.4)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background {
                                Capsule()
                                    .fill(Color.brandRed)
                                    .shadow(color: .brandRed.opacity(0.28), radius: 10, x: 0, y: 4)
                            }
                    }
                    .accessibilityLabel("Abilita notifiche")

                    Button(action: onSkip) {
                        Text("Non ora")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.brandGray)
                            .frame(height: 44)
                    }
                    .accessibilityLabel("Non ora, salta le notifiche")
                }
                .padding(.horizontal, 24)
                .safeAreaPadding(.bottom)
                .padding(.bottom, 16)
            }
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Feature card (same visual as OnboardingPillarCard)

private struct NotificationFeatureCard: View {
    let icon: String
    let color: Color
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            RoundedRectangle(cornerRadius: 13)
                .fill(color.opacity(0.1))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(color)
                }
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.brandBlack)
                    .kerning(-0.3)
                Text(detail)
                    .font(.system(size: 13))
                    .foregroundStyle(.brandGray)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background {
            RoundedRectangle(cornerRadius: 18)
                .fill(.white.opacity(0.78))
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(.white.opacity(0.75), lineWidth: 0.5)
                }
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(detail)")
    }
}

// MARK: - Preview

#Preview {
    NotificationPermissionView(onAllow: {}, onSkip: {})
}
