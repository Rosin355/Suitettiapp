import SwiftUI

struct HomeEventsSection: View {
    @Environment(EventStore.self) private var store

    /// The Home preview omits the event already promoted by the banner directly above,
    /// so the same card never appears twice in one screenful. This is a Home-only
    /// presentation choice — `EventiView` still lists every event.
    private var previewEvents: [Event] {
        let promotedID = store.featuredEvent?.id
        return Array(store.upcomingEvents.lazy.filter { $0.id != promotedID }.prefix(3))
    }

    /// True when the only upcoming event is the one already in the banner. Showing
    /// "Nessun evento in programma" directly under a banner advertising an upcoming
    /// event would contradict itself, so the whole section stands down instead.
    private var isFullyPromoted: Bool {
        previewEvents.isEmpty && !store.upcomingEvents.isEmpty
    }

    var body: some View {
        if !isFullyPromoted {
            content
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("Prossimi eventi")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(.brandBlack)
                Spacer()
                NavigationLink("Tutti →") {
                    EventiView()
                        .navigationTitle("Eventi")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.brandRed)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 10)

            if previewEvents.isEmpty {
                Text("Nessun evento in programma.")
                    .font(.system(size: 14))
                    .foregroundStyle(.brandGray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .padding(.horizontal, DT.padding)
            } else {
                GCard {
                    VStack(spacing: 0) {
                        ForEach(Array(previewEvents.enumerated()), id: \.element.id) { index, event in
                            NavigationLink(destination: EventDetailView(event: event)) {
                                EventRow(
                                    day:    event.day,
                                    month:  event.monthShort,
                                    title:  event.title,
                                    place:  placeText(event),
                                    isLast: index == previewEvents.count - 1
                                )
                            }
                            .buttonStyle(PressableCardStyle())
                        }
                    }
                }
                .padding(.horizontal, DT.padding)
                .padding(.bottom, 12)
            }
        }
        .appearAnimation(delay: 0.2)
    }

    private func placeText(_ event: Event) -> String {
        var parts: [String] = []
        if !event.location.isEmpty { parts.append(event.location) }
        if !event.time.isEmpty     { parts.append("ore \(event.time)") }
        return parts.joined(separator: " · ")
    }
}
