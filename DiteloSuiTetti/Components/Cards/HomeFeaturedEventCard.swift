import SwiftUI

/// Home banner for the event the CMS is currently promoting (`events.is_featured`).
///
/// Replaces the old hardcoded Festival spotlight: nothing here is bound to a specific
/// event, so the card stays correct forever as editors change what is featured. It
/// renders only when `EventStore` resolves a featured event, and the whole card is a
/// single tap target that pushes the native `EventDetailView` — never the website.
///
/// Text sizes use `@ScaledMetric` so the card honours Dynamic Type while keeping the
/// design system's exact metrics at the default size.
struct HomeFeaturedEventCard: View {
    let event: Event

    @ScaledMetric(relativeTo: .title3)   private var titleSize: CGFloat = 20
    @ScaledMetric(relativeTo: .subheadline) private var metaSize: CGFloat = 14
    @ScaledMetric(relativeTo: .subheadline) private var ctaSize: CGFloat = 15
    /// Cover height scales too, so the image never dwarfs the text at large sizes.
    @ScaledMetric(relativeTo: .body)     private var coverHeight: CGFloat = 170

    var body: some View {
        NavigationLink(destination: EventDetailView(event: event)) {
            VStack(alignment: .leading, spacing: 0) {
                cover
                details
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white)
            .clipShape(.rect(cornerRadius: DT.cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: DT.cornerRadius)
                    .strokeBorder(.white.opacity(0.8), lineWidth: 0.5)
            }
            .cardShadow()
        }
        .buttonStyle(PressableCardStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Apri i dettagli dell'evento")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Cover

    /// `RemoteImageView` already falls back to the official brand artwork when the
    /// event has no image or the download fails, so there is no bespoke placeholder
    /// and no duplicated image-loading logic here.
    private var cover: some View {
        ZStack(alignment: .bottomLeading) {
            RemoteImageView(url: event.imageURL, logTitle: event.title)
                .frame(height: coverHeight)
                .frame(maxWidth: .infinity)
                .clipped()

            // Keeps the chip legible over bright or busy photography.
            LinearGradient(
                colors: [.clear, .black.opacity(0.45)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: coverHeight * 0.5)
            .allowsHitTesting(false)

            CategoryChip(
                text: "EVENTO IN EVIDENZA",
                color: .brandBlack,
                background: .brandYellow
            )
            .padding(12)
        }
        .accessibilityHidden(true)
    }

    // MARK: - Details

    private var details: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(TextNormalizer.singleLineClean(event.title))
                .font(.system(size: titleSize, weight: .bold))
                .foregroundStyle(.brandBlack)
                .kerning(-0.4)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 6) {
                metaRow(icon: "calendar", text: dateText)
                if !event.location.isEmpty {
                    metaRow(icon: "mappin.and.ellipse", text: event.location)
                }
            }

            Divider().overlay(Color.brandSep)

            HStack(spacing: 12) {
                Text("Scopri l'evento")
                    .font(.system(size: ctaSize, weight: .semibold))
                    .foregroundStyle(.brandRed)

                Spacer(minLength: 8)

                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(.brandRed)
                    .clipShape(.rect(cornerRadius: 11))
            }
        }
        .padding(16)
    }

    private func metaRow(icon: String, text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: metaSize * 0.86))
                .foregroundStyle(.brandRed)
                .frame(width: 16)
            Text(text)
                .font(.system(size: metaSize))
                .foregroundStyle(.brandGray)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Derived text

    private var dateText: String {
        event.time.isEmpty ? event.fullDate : "\(event.fullDate) · ore \(event.time)"
    }

    /// Spoken as one phrase so VoiceOver announces the whole card in a single swipe.
    private var accessibilityLabel: String {
        var parts = ["Evento in evidenza", TextNormalizer.singleLineClean(event.title), dateText]
        if !event.location.isEmpty { parts.append(event.location) }
        return parts.joined(separator: ". ")
    }
}

#Preview("With image") {
    NavigationStack {
        ScrollView {
            HomeFeaturedEventCard(event: Event.all[0])
                .padding(DT.padding)
        }
        .background(Color.brandCream)
    }
}

#Preview("No image — brand fallback") {
    NavigationStack {
        ScrollView {
            HomeFeaturedEventCard(
                event: Event(
                    id: UUID(),
                    title: "Assemblea pubblica dei comitati civici",
                    slug: "assemblea-pubblica",
                    type: "Evento",
                    day: "16",
                    monthShort: "OTT",
                    fullDate: "16 ottobre 2026",
                    time: "18:30",
                    location: "Roma · Pio Sodalizio dei Piceni",
                    description: "Un incontro aperto a tutti.",
                    link: nil,
                    imageURL: nil,
                    rawDate: Date().addingTimeInterval(86_400 * 30),
                    updatedAt: Date(),
                    syncVersion: 1,
                    isFeatured: true
                )
            )
            .padding(DT.padding)
        }
        .background(Color.brandCream)
    }
}
