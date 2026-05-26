import SwiftUI

// MARK: - Onboarding container

struct OnboardingView: View {
    let onComplete: () -> Void

    @State private var currentSlide = 0
    private let totalSlides = 3

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
                                    ? Color.white.opacity(0.6)
                                    : Color.brandGrayLight
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
            if currentSlide < totalSlides - 1 {
                currentSlide += 1
            } else {
                onComplete()
            }
        } label: {
            Text(currentSlide < totalSlides - 1 ? "Avanti" : "Inizia →")
                .font(.system(size: 17, weight: .bold))
                .kerning(-0.4)
                .foregroundStyle(currentSlide == 0 ? Color.brandRed : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background {
                    ZStack {
                        // Slide 0: frosted glass pill
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .environment(\.colorScheme, .dark)
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                            .opacity(currentSlide == 0 ? 1 : 0)
                        // Slides 1–2: solid red pill
                        Capsule()
                            .fill(Color.brandRed)
                            .shadow(color: .brandRed.opacity(0.28), radius: 10, x: 0, y: 4)
                            .opacity(currentSlide == 0 ? 0 : 1)
                    }
                }
        }
        .animation(.easeInOut(duration: 0.2), value: currentSlide)
        .accessibilityLabel(currentSlide < totalSlides - 1 ? "Avanti" : "Inizia")
    }

    private var dotColor: Color {
        currentSlide == 1 ? .brandRed : .white
    }
}

// MARK: - Slide 0: Brand hero (red)

private struct OnboardingSlide0: View {
    var body: some View {
        ZStack {
            Color.brandRed.ignoresSafeArea()
            orbs
            content
        }
    }

    private var orbs: some View {
        GeometryReader { geo in
            // Large orb — top-right, partially off-screen
            Circle()
                .fill(.white.opacity(0.06))
                .frame(width: 300, height: 300)
                .position(x: geo.size.width - 90, y: 60)
            // Small orb — bottom-left, partially off-screen
            Circle()
                .fill(.black.opacity(0.05))
                .frame(width: 160, height: 160)
                .position(x: 40, y: geo.size.height - 140)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var content: some View {
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Ditelo sui Tetti. La voce civica per la vita, la famiglia e l'educazione.")
    }

    private var logoMark: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .frame(width: 64, height: 64)
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(.white.opacity(0.35), lineWidth: 0.5)
                }
                .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
            OnboardingLogoIcon()
                .frame(width: 30, height: 30)
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Slide 1: Mission pillars (cream)

private struct OnboardingSlide1: View {
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

    var body: some View {
        ZStack {
            Color.brandCream.ignoresSafeArea()

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
                            color:   pillars[i].color,
                            icon:    pillars[i].icon,
                            title:   pillars[i].title,
                            detail:  pillars[i].detail
                        )
                    }
                }
            }
            .padding(.horizontal, 24)
            .safeAreaPadding(.top)
            .padding(.top, 36)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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

// MARK: - Slide 2: Referendum (dark)

private struct OnboardingSlide2: View {
    var body: some View {
        ZStack {
            Color(red: 26/255, green: 26/255, blue: 26/255).ignoresSafeArea()
            orbs
            content
        }
    }

    private var orbs: some View {
        GeometryReader { geo in
            Circle()
                .fill(Color.brandRed.opacity(0.10))
                .frame(width: 240, height: 240)
                .position(x: geo.size.width - 70, y: 60)
            Circle()
                .fill(Color.brandRed.opacity(0.06))
                .frame(width: 160, height: 160)
                .position(x: 50, y: geo.size.height - 140)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("REFERENDUM · 12 GIU 2026")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.brandRed)
                .kerning(0.3)
                .padding(.horizontal, 11)
                .padding(.vertical, 4)
                .background(.brandRed.opacity(0.18))
                .clipShape(Capsule())
                .padding(.bottom, 22)

            Text("Separazione")
                .font(.system(size: 52, weight: .black))
                .foregroundStyle(.white)
                .kerning(-2)

            Text("delle carriere.")
                .font(.system(size: 52, weight: .black))
                .foregroundStyle(.white)
                .kerning(-2)
                .padding(.bottom, 12)

            Text("Vota Sì.")
                .font(Font.custom("Georgia", size: 28).italic())
                .foregroundStyle(.brandRed)
                .kerning(-0.5)
                .padding(.bottom, 24)

            Text("Una riforma per una magistratura più indipendente e processi più equi per tutti.")
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.56))
                .lineSpacing(6)
                .kerning(-0.2)
                .frame(maxWidth: 290, alignment: .leading)
        }
        .padding(.horizontal, 28)
        .safeAreaPadding(.top)
        .padding(.top, 46)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Referendum, 12 giugno 2026. Separazione delle carriere. Vota Sì. " +
            "Una riforma per una magistratura più indipendente e processi più equi per tutti."
        )
    }
}

// MARK: - Logo icon (SVG faithfully reproduced)

private struct OnboardingLogoIcon: View {
    var body: some View {
        Canvas { ctx, size in
            let s = min(size.width, size.height) / 30

            // Vertical + curved arm going to top-right
            ctx.stroke(
                Path { p in
                    p.move(to: CGPoint(x: 7*s, y: 22*s))
                    p.addLine(to: CGPoint(x: 7*s, y: 12*s))
                    p.addCurve(
                        to: CGPoint(x: 14*s, y: 5*s),
                        control1: CGPoint(x: 7*s, y: 8.134*s),
                        control2: CGPoint(x: 10.134*s, y: 5*s)
                    )
                    p.addLine(to: CGPoint(x: 23*s, y: 5*s))
                },
                with: .foreground,
                style: StrokeStyle(lineWidth: 2.4*s, lineCap: .round, lineJoin: .round)
            )

            // Circle at base of arm
            ctx.fill(
                Path(ellipseIn: CGRect(
                    x: (7 - 3.5)*s, y: (25 - 3.5)*s,
                    width: 7*s, height: 7*s
                )),
                with: .foreground
            )

            // Bottom horizontal bar
            ctx.stroke(
                Path { p in
                    p.move(to: CGPoint(x: 12*s, y: 25*s))
                    p.addLine(to: CGPoint(x: 23*s, y: 25*s))
                },
                with: .foreground,
                style: StrokeStyle(lineWidth: 2.4*s, lineCap: .round)
            )

            // Center vertical bar
            ctx.stroke(
                Path { p in
                    p.move(to: CGPoint(x: 17.5*s, y: 25*s))
                    p.addLine(to: CGPoint(x: 17.5*s, y: 18*s))
                },
                with: .foreground,
                style: StrokeStyle(lineWidth: 2.4*s, lineCap: .round)
            )

            // Top horizontal bar
            ctx.stroke(
                Path { p in
                    p.move(to: CGPoint(x: 23*s, y: 18*s))
                    p.addLine(to: CGPoint(x: 12*s, y: 18*s))
                },
                with: .foreground,
                style: StrokeStyle(lineWidth: 2.4*s, lineCap: .round)
            )
        }
    }
}

// MARK: - Previews

#Preview("Slide 0") {
    OnboardingView(onComplete: {})
}

#Preview("Slide 1") {
    OnboardingView(onComplete: {})
}

#Preview("Slide 2") {
    OnboardingView(onComplete: {})
}
