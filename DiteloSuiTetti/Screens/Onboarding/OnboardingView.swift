import SwiftUI

// MARK: - Onboarding container

struct OnboardingView: View {
    let onComplete: () -> Void

    @State private var currentSlide   = 0
    @State private var hapticTrigger  = 0
    private let totalSlides           = 3

    var body: some View {
        ZStack {
            // Slide content — fills full screen, swipeable
            TabView(selection: $currentSlide) {
                OnboardingSlide0().tag(0)
                OnboardingSlide1().tag(1)
                OnboardingSlide2().tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            // Skip button (hidden on last slide)
            if currentSlide < totalSlides - 1 {
                VStack {
                    HStack {
                        Spacer()
                        Button("Salta", action: onComplete)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(
                                currentSlide == 0
                                    ? Color.brandGrayLight
                                    : Color.white.opacity(0.6)
                            )
                            .padding(.trailing, 20)
                            .padding(.top, 8)
                    }
                    .safeAreaPadding(.top)
                    Spacer()
                }
            }

            // Dot indicator + CTA
            VStack {
                Spacer()
                VStack(spacing: 20) {
                    dots
                    ctaButton
                }
                .padding(.horizontal, 24)
                .safeAreaPadding(.bottom)
                .padding(.bottom, 16)
            }
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Dot indicator

    private var dots: some View {
        HStack(spacing: 7) {
            ForEach(0..<totalSlides, id: \.self) { i in
                Capsule()
                    .fill(dotColor.opacity(i == currentSlide ? 1 : 0.28))
                    .frame(width: i == currentSlide ? 26 : 6, height: 6)
                    .animation(
                        .spring(response: 0.3, dampingFraction: 0.8),
                        value: currentSlide
                    )
                    .onTapGesture { currentSlide = i }
                    .accessibilityHidden(true)
            }
        }
    }

    // MARK: - CTA button

    private var ctaButton: some View {
        Button {
            hapticTrigger += 1
            if currentSlide < totalSlides - 1 {
                currentSlide += 1
            } else {
                onComplete()
            }
        } label: {
            Text(currentSlide < totalSlides - 1 ? "Avanti" : "Inizia →")
                .font(.system(size: 17, weight: .bold))
                .kerning(-0.4)
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background {
                    ZStack {
                        // Slide 1 (red): frosted glass pill
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .environment(\.colorScheme, .dark)
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                            .opacity(currentSlide == 1 ? 1 : 0)
                        // Slides 0 + 2: solid red pill
                        Capsule()
                            .fill(Color.brandRed)
                            .shadow(color: .brandRed.opacity(0.28), radius: 10, x: 0, y: 4)
                            .opacity(currentSlide == 1 ? 0 : 1)
                    }
                }
        }
        .animation(.easeInOut(duration: 0.2), value: currentSlide)
        .sensoryFeedback(.selection, trigger: hapticTrigger)
        .accessibilityLabel(currentSlide < totalSlides - 1 ? "Avanti" : "Inizia")
    }

    private var dotColor: Color {
        currentSlide == 0 ? .brandRed : .white
    }
}

// MARK: - Slide 0: Mission pillars (cream)

private struct OnboardingSlide0: View {
    private let pillars: [(color: Color, icon: String, title: String, detail: String)] = [
        (
            .brandRed, "heart.fill", "Famiglia",
            "Sosteniamo la famiglia come fondamento della società civile"
        ),
        (
            Color(red: 42/255, green: 122/255, blue: 75/255), "book.fill", "Educazione",
            "Difendiamo la libertà educativa delle famiglie italiane"
        ),
        (
            Color(red: 91/255, green: 82/255, blue: 208/255), "network", "Sussidiarietà",
            "Promuoviamo reti civiche costruite dal basso per il bene comune"
        ),
    ]

    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.brandCream.ignoresSafeArea()
            OnboardingBokehBackground(theme: .cream)

            VStack(alignment: .leading, spacing: 0) {
                Text("Chi siamo")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.brandGray)
                    .kerning(1.5)
                    .textCase(.uppercase)
                    .padding(.bottom, 10)

                Text("La nostra\nmissione.")
                    .font(.system(size: 42, weight: .black))
                    .foregroundStyle(.brandBlack)
                    .kerning(-1.5)
                    .lineSpacing(4)
                    .padding(.bottom, 28)

                VStack(spacing: 10) {
                    ForEach(pillars.indices, id: \.self) { i in
                        OnboardingPillarCard(
                            color:  pillars[i].color,
                            icon:   pillars[i].icon,
                            title:  pillars[i].title,
                            detail: pillars[i].detail
                        )
                    }
                }
            }
            .padding(.horizontal, 24)
            .safeAreaPadding(.top)
            .padding(.top, 36)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)
            .animation(.easeOut(duration: 0.35).delay(0.05), value: appeared)
            .onAppear { appeared = true }
        }
    }
}

private struct OnboardingPillarCard: View {
    let color: Color
    let icon: String
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

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
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

// MARK: - Slide 1: Brand hero (red)

private struct OnboardingSlide1: View {
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.brandRed.ignoresSafeArea()
            OnboardingBokehBackground(theme: .red)

            VStack(alignment: .leading, spacing: 0) {
                logoMark
                    .padding(.bottom, 38)
                    .accessibilityHidden(true)

                Text("Ditelo")
                    .font(.system(size: 74, weight: .black))
                    .foregroundStyle(.white)
                    .kerning(-3)

                Text("sui Tetti.")
                    .font(Font.custom("Georgia", size: 70).italic())
                    .foregroundStyle(.brandYellowLight)
                    .kerning(-2)
                    .padding(.bottom, 30)

                Text("La voce civica per la vita, la famiglia e l'educazione.")
                    .font(.system(size: 17))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineSpacing(6)
                    .frame(maxWidth: 280, alignment: .leading)
            }
            .padding(.horizontal, 28)
            .safeAreaPadding(.top)
            .padding(.top, 50)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)
            .animation(.easeOut(duration: 0.35).delay(0.05), value: appeared)
            .onAppear { appeared = true }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Ditelo sui Tetti. La voce civica per la vita, la famiglia e l'educazione.")
        }
    }

    private var logoMark: some View {
        Image(uiImage: UIImage(named: "AppIcon") ?? UIImage())
            .resizable()
            .scaledToFit()
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 3)
    }
}

// MARK: - Slide 2: Festival (dark)

private struct OnboardingSlide2: View {
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color(red: 26/255, green: 26/255, blue: 26/255).ignoresSafeArea()
            OnboardingBokehBackground(theme: .dark)

            VStack(alignment: .leading, spacing: 0) {
                // Badge
                Text("3° FESTIVAL")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.brandBlack)
                    .kerning(0.8)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(.brandYellow.opacity(0.9))
                    .clipShape(Capsule())
                    .padding(.bottom, 22)

                // Title
                Text("SUI TETTI")
                    .font(.system(size: 48, weight: .black))
                    .foregroundStyle(.white)
                    .kerning(-2)
                Text("FESTIVAL 2026")
                    .font(.system(size: 48, weight: .black))
                    .foregroundStyle(.white)
                    .kerning(-2)
                    .padding(.bottom, 16)

                // Italic gold subtitle
                Text("Insieme per il bene\ncomune.")
                    .font(Font.custom("Georgia", size: 26).italic())
                    .foregroundStyle(.brandYellowLight)
                    .kerning(-0.5)
                    .lineSpacing(5)
                    .padding(.bottom, 22)

                // Body
                Text("Tre giorni di incontri, idee e testimonianze per costruire una società più giusta, solidale e sussidiaria.")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.56))
                    .lineSpacing(6)
                    .kerning(-0.2)
                    .frame(maxWidth: 300, alignment: .leading)

                // Closing
                Text("Ti aspettiamo. ♡")
                    .font(Font.custom("Georgia", size: 17).italic())
                    .foregroundStyle(.white.opacity(0.70))
                    .padding(.top, 14)
            }
            .padding(.horizontal, 28)
            .safeAreaPadding(.top)
            .padding(.top, 46)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)
            .animation(.easeOut(duration: 0.35).delay(0.05), value: appeared)
            .onAppear { appeared = true }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(
                "3° Festival. Sui Tetti Festival 2026. " +
                "Insieme per il bene comune. " +
                "Tre giorni di incontri, idee e testimonianze per costruire una società più giusta, solidale e sussidiaria. " +
                "Ti aspettiamo."
            )
        }
    }
}

// MARK: - Previews

#Preview("Slide 0 — Mission") {
    OnboardingView(onComplete: {})
}

#Preview("Slide 1 — Brand") {
    OnboardingView(onComplete: {})
}

#Preview("Slide 2 — Festival") {
    OnboardingView(onComplete: {})
}
