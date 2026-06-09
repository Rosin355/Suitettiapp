import SwiftUI

// Consistent horizontal margin for all About content — matches SectionHeader.
private let aboutHPad: CGFloat = 20

struct AboutView: View {
    @State private var showDonation = false
    @State private var showRateApp  = false
    @State private var showSocial   = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                AboutHeroSection()
                AboutMissionSection()
                AboutSupportCTA { showDonation = true }
                AboutSettingsSection(
                    onShowSocial:   { showSocial = true },
                    onShowRateApp:  { showRateApp = true }
                )
                AboutSupportSection()
                AboutDeveloperSection()
            }
            // Constrain card content to readable width on iPad
            .frame(maxWidth: horizontalSizeClass == .regular ? DT.readableMaxWidth : .infinity)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .background(.brandCream)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.brandCream, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .sheet(isPresented: $showDonation) { SupportDonationSheet() }
        .sheet(isPresented: $showRateApp)  { RateAppSheet() }
        .sheet(isPresented: $showSocial)   { SocialLinksSheet() }
    }
}

// MARK: - Hero

private struct AboutHeroSection: View {
    var body: some View {
        Text("Ditelo sui Tetti è uno spazio civico ed editoriale nato per dare voce a chi crede nella famiglia, nella libertà educativa, nella sussidiarietà e nel bene comune.")
            .font(.system(size: 17))
            .foregroundStyle(.brandBlack.opacity(0.82))
            .lineSpacing(5)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, aboutHPad)
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
            .padding(.horizontal, aboutHPad)
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
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Compact support CTA

private struct AboutSupportCTA: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.brandRed)
                        .frame(width: 44, height: 44)
                    Image(systemName: "heart.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Sostieni Ditelo sui Tetti")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .kerning(-0.3)
                    Text("Il tuo contributo aiuta a far crescere una voce civica libera.")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.65))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Scopri come")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                LinearGradient(
                    colors: [.brandBlack, Color(red: 42/255, green: 42/255, blue: 42/255)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            }
            .clipShape(.rect(cornerRadius: DT.cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: DT.cornerRadius)
                    .strokeBorder(.white.opacity(0.10), lineWidth: 0.5)
            }
            .cardShadow()
        }
        .buttonStyle(.plain)
        .padding(.horizontal, aboutHPad)
        .padding(.top, 8)
        .padding(.bottom, 14)
        .accessibilityLabel("Sostieni Ditelo sui Tetti. Scopri come fare una donazione.")
    }
}

// MARK: - Settings rows

private struct AboutSettingsSection: View {
    let onShowSocial:  () -> Void
    let onShowRateApp: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            SectionHeader(title: "Impostazioni")

            VStack(spacing: 0) {
                // Privacy Policy — native in-app screen
                NavigationLink(destination: PrivacyPolicyView()) {
                    SettingsRow(icon: "lock.shield.fill", label: "Privacy Policy")
                }
                .buttonStyle(.plain)

                // Termini e condizioni — hidden until ready
                // NavigationLink(destination: WebPageView(title: "Termini e condizioni", url: AppEnvironment.termsURL)) {
                //     SettingsRow(icon: "doc.text.fill", label: "Termini e condizioni")
                // }
                // .buttonStyle(.plain)

                Divider().padding(.leading, 58)

                // Social links
                Button { onShowSocial() } label: {
                    SettingsRow(icon: "person.2.fill", label: "Seguici sui social")
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

                Button { onShowRateApp() } label: {
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
            .padding(.horizontal, aboutHPad)
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

// MARK: - Technical support

private struct AboutSupportSection: View {
    @State private var showMailError = false

    var body: some View {
        VStack(spacing: 0) {
            SectionHeader(title: "Supporto tecnico")

            GCard {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top, spacing: 12) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.brandRed.opacity(0.08))
                            .frame(width: 44, height: 44)
                            .overlay {
                                Image(systemName: "wrench.and.screwdriver.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(.brandRed)
                            }
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Hai bisogno di aiuto?")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(.brandBlack)
                                .kerning(-0.3)
                            Text("Per problemi tecnici o segnalazioni sull'app, contatta il team di sviluppo.")
                                .font(.system(size: 13))
                                .foregroundStyle(.brandGray)
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                    Divider().padding(.horizontal, 16)

                    Button { contactSupport() } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.brandRed)
                            Text("Scrivi a Digital Yogin")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.brandRed)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.brandRed.opacity(0.7))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Contatta il supporto tecnico Digital Yogin")
                }
            }
            .padding(.horizontal, aboutHPad)
            .padding(.bottom, 14)
        }
        .alert("Mail non disponibile", isPresented: $showMailError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Non è possibile aprire Mail. Puoi scrivere a \(AppEnvironment.supportEmail)")
        }
    }

    private func contactSupport() {
        guard let url = supportMailURL() else {
            showMailError = true
            return
        }
        NSLog("[Support] opening mail composer to %@", AppEnvironment.supportEmail)
        UIApplication.shared.open(url, options: [:]) { success in
            if !success {
                NSLog("[Support] ✗ Mail unavailable — showing fallback alert")
                showMailError = true
            }
        }
    }

    /// Builds a `mailto:` URL with a version/build-stamped subject and a body
    /// template, percent-encoding both with a strict unreserved-only set.
    private func supportMailURL() -> URL? {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        let build   = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
        let subject = "Supporto Ditelo sui Tetti iOS v\(version) (\(build))"
        let body = """
        Ciao Digital Yogin,

        ho bisogno di supporto per l'app Ditelo sui Tetti.

        Descrizione del problema:

        """
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        let s = subject.addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
        let b = body.addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
        return URL(string: "mailto:\(AppEnvironment.supportEmail)?subject=\(s)&body=\(b)")
    }
}

// MARK: - Developer info

private struct AboutDeveloperSection: View {
    private let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    private let build   = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"

    private let techStack1 = ["Swift", "SwiftUI", "SwiftData", "Supabase"]
    private let techStack2 = ["PDFKit", "WebKit", "APNs"]

    var body: some View {
        VStack(spacing: 0) {
            SectionHeader(title: "Sviluppo e tecnologia")

            GCard {
                VStack(alignment: .leading, spacing: 0) {
                    // Identity row
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.brandRed.opacity(0.08))
                            .frame(width: 44, height: 44)
                            .overlay {
                                Image(systemName: "curlybraces")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(.brandRed)
                            }
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Digital Yogin srl")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(.brandBlack)
                                .kerning(-0.3)
                            Text("Partner tecnologico e sviluppo software")
                                .font(.system(size: 12))
                                .foregroundStyle(.brandGray)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                    Divider().padding(.horizontal, 16)

                    // Description
                    Text("L'app SUITETTI è sviluppata con codice nativo Swift e SwiftUI, integrata con backend Supabase, caching locale e architettura mobile-first.")
                        .font(.system(size: 13))
                        .foregroundStyle(.brandGray)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 12)

                    // Tech stack chips
                    VStack(alignment: .leading, spacing: 6) {
                        techChipRow(techStack1)
                        techChipRow(techStack2)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)

                    Divider().padding(.horizontal, 16)

                    // Website link
                    Button {
                        UIApplication.shared.open(AppEnvironment.digitalYoginURL)
                    } label: {
                        HStack(spacing: 6) {
                            Text("Visita Digital Yogin")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.brandRed)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.brandRed.opacity(0.7))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Visita il sito di Digital Yogin")
                }
            }
            .padding(.horizontal, aboutHPad)
            .padding(.bottom, 14)

            // Version footer — small and unobtrusive
            Text("Versione \(version) (\(build))")
                .font(.system(size: 12))
                .foregroundStyle(.brandGrayLight)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 140)
        }
    }

    @ViewBuilder
    private func techChipRow(_ chips: [String]) -> some View {
        HStack(spacing: 6) {
            ForEach(chips, id: \.self) { chip in
                Text(chip)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.brandGray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.brandGray.opacity(0.09))
                    .clipShape(.rect(cornerRadius: 6))
            }
        }
    }
}

// MARK: - Previews

#Preview("Chi siamo – Light") {
    NavigationStack {
        AboutView()
            .navigationTitle("Chi siamo")
    }
}

#Preview("Chi siamo – Dark") {
    NavigationStack {
        AboutView()
            .navigationTitle("Chi siamo")
    }
    .preferredColorScheme(.dark)
}

#Preview("Donation Sheet") {
    SupportDonationSheet()
}

#Preview("Rate App Sheet") {
    RateAppSheet()
}

#Preview("Social Links Sheet") {
    SocialLinksSheet()
}
