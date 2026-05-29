import SwiftUI
import StoreKit

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                AboutHeroSection()
                AboutMissionSection()
                AboutSupportCard()
                    .padding(.top, 8)
                AboutSettingsSection()
                AboutDeveloperSection()
            }
        }
        .scrollIndicators(.hidden)
        .background(.brandCream)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
    }
}

// MARK: - Hero

private struct AboutHeroSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ditelo sui Tetti è uno spazio civico ed editoriale nato per dare voce a chi crede nella famiglia, nella libertà educativa, nella sussidiarietà e nel bene comune.")
                .font(.system(size: 17))
                .foregroundStyle(.brandBlack.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DT.padding)
        .padding(.top, 16)
        .padding(.bottom, 24)
    }
}

// MARK: - Mission cards

private struct AboutMissionSection: View {
    private let pillars: [(icon: String, title: String, detail: String)] = [
        ("heart.fill",               "Famiglia",      "Sosteniamo la famiglia come fondamento della società civile."),
        ("book.fill",                "Educazione",    "Difendiamo la libertà educativa e il primato dei genitori."),
        ("globe.europe.africa.fill", "Sussidiarietà", "Crediamo nel protagonismo della società civile."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            SectionHeader(title: "I nostri valori")

            VStack(spacing: 8) {
                ForEach(pillars, id: \.title) { pillar in
                    PillarCard(pillar: pillar)
                }
            }
            .padding(.horizontal, DT.padding)
            .padding(.bottom, 16)
        }
    }
}

private struct PillarCard: View {
    let pillar: (icon: String, title: String, detail: String)

    var body: some View {
        GCard {
            HStack(alignment: .top, spacing: 14) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.brandRed.opacity(0.08))
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: pillar.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.brandRed)
                    }
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text(pillar.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.brandBlack)
                        .kerning(-0.3)
                    Text(pillar.detail)
                        .font(.system(size: 13))
                        .foregroundStyle(.brandGray)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }
}

// MARK: - Support CTA

private struct AboutSupportCard: View {
    var body: some View {
        GCard {
            VStack(alignment: .leading, spacing: 0) {
                Text("iniziativa civica")
                    .font(.georgiaItalic(13))
                    .foregroundStyle(.brandGrayLight)
                    .padding(.bottom, 10)

                Text("Sostieni\nDitelo sui Tetti")
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(.white)
                    .kerning(-0.5)
                    .lineSpacing(2)
                    .padding(.bottom, 10)

                Text("Il tuo contributo aiuta a far crescere una voce civica libera, indipendente e condivisa.")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.65))
                    .lineSpacing(3)
                    .padding(.bottom, 20)

                Button {
                    if let url = URL(string: AppEnvironment.websiteURL.absoluteString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Sostienici →")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(height: 48)
                        .padding(.horizontal, 22)
                        .background(.brandRed)
                        .clipShape(Capsule())
                        .shadow(color: .brandRed.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .accessibilityLabel("Sostieni la rete civica")
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                ZStack(alignment: .topTrailing) {
                    LinearGradient(
                        colors: [.brandBlack, Color(red: 42/255, green: 42/255, blue: 42/255)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    Circle()
                        .fill(.brandRed.opacity(0.15))
                        .frame(width: 120, height: 120)
                        .offset(x: 20, y: -20)
                }
            }
        }
        .padding(.horizontal, DT.padding)
        .padding(.bottom, 14)
    }
}

// MARK: - Settings rows

private struct AboutSettingsSection: View {
    @Environment(\.requestReview) private var requestReview

    var body: some View {
        VStack(spacing: 0) {
            SectionHeader(title: "Impostazioni")

            VStack(spacing: 0) {
                NavigationLink(destination: WebPageView(title: "Privacy Policy", url: AppEnvironment.privacyPolicyURL)) {
                    SettingsRow(icon: "lock.shield.fill", label: "Privacy Policy")
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 58)

                NavigationLink(destination: WebPageView(title: "Termini e condizioni", url: AppEnvironment.termsURL)) {
                    SettingsRow(icon: "doc.text.fill", label: "Termini e condizioni")
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 58)

                Button {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    UIApplication.shared.open(url)
                } label: {
                    SettingsRow(icon: "bell.fill", label: "Gestisci notifiche")
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 58)

                Button {
                    requestReview()
                } label: {
                    SettingsRow(icon: "star.fill", label: "Valuta l'app")
                }
                .buttonStyle(.plain)
            }
            .background(.white.opacity(0.82))
            .clipShape(.rect(cornerRadius: DT.cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: DT.cornerRadius)
                    .strokeBorder(.white.opacity(0.75), lineWidth: 0.5)
            }
            .cardShadow()
            .padding(.horizontal, DT.padding)
            .padding(.bottom, 16)
        }
    }
}

private struct SettingsRow: View {
    let icon: String
    let label: String

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 10)
                .fill(.brandRed.opacity(0.08))
                .frame(width: 36, height: 36)
                .overlay {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.brandRed)
                }
                .accessibilityHidden(true)

            Text(label)
                .font(.system(size: 16))
                .foregroundStyle(.brandBlack)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.brandGrayLight)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

// MARK: - Developer info

private struct AboutDeveloperSection: View {
    private let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    private let build   = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"

    var body: some View {
        VStack(spacing: 0) {
            SectionHeader(title: "Sviluppo")

            VStack(spacing: 0) {
                infoRow(label: "Versione", value: "\(version) (\(build))")
                Divider().padding(.leading, 16)
                infoRow(label: "Partner tecnologico", value: "Digital Yogin srl")
                Divider().padding(.leading, 16)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sviluppo software, architettura iOS e integrazione backend.")
                        .font(.system(size: 13))
                        .foregroundStyle(.brandGray)
                        .lineSpacing(3)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(.white.opacity(0.82))
            .clipShape(.rect(cornerRadius: DT.cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: DT.cornerRadius)
                    .strokeBorder(.white.opacity(0.75), lineWidth: 0.5)
            }
            .cardShadow()
            .padding(.horizontal, DT.padding)
            .padding(.bottom, 100)
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(.brandBlack)
            Spacer()
            Text(value)
                .font(.system(size: 15))
                .foregroundStyle(.brandGray)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AboutView()
            .navigationTitle("Chi siamo")
    }
}
