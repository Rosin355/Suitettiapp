import SwiftUI

struct HomeEventsSection: View {
    @Environment(EventStore.self) private var store

    private var featured: [Event] {
        Array(store.upcomingEvents.prefix(3))
    }

    var body: some View {
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

            if featured.isEmpty {
                Text("Nessun evento in programma.")
                    .font(.system(size: 14))
                    .foregroundStyle(.brandGray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .padding(.horizontal, DT.padding)
            } else {
                GCard {
                    VStack(spacing: 0) {
                        ForEach(Array(featured.enumerated()), id: \.element.id) { index, event in
                            NavigationLink(destination: EventDetailView(event: event)) {
                                EventRow(
                                    day:    event.day,
                                    month:  event.monthShort,
                                    title:  event.title,
                                    place:  placeText(event),
                                    isLast: index == featured.count - 1
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, DT.padding)
                .padding(.bottom, 12)
            }
        }
    }

    private func placeText(_ event: Event) -> String {
        var parts: [String] = []
        if !event.location.isEmpty { parts.append(event.location) }
        if !event.time.isEmpty     { parts.append("ore \(event.time)") }
        return parts.joined(separator: " · ")
    }
}
