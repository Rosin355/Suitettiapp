import SwiftUI

struct EventiView: View {
    @Environment(EventStore.self) private var store

    var body: some View {
        Group {
            if store.isLoading {
                loadingView
            } else if let message = store.errorMessage {
                errorView(message: message)
            } else if store.upcomingEvents.isEmpty {
                emptyView
            } else {
                eventList
            }
        }
        .background(.brandCream)
        .task { await store.load() }
        .refreshable { await store.refresh() }
    }

    // MARK: - List

    private var eventList: some View {
        ScrollView {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(.white.opacity(0.8))
                    .frame(height: 1)

                let events = store.upcomingEvents
                ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                    NavigationLink(destination: EventDetailView(event: event)) {
                        EventRow(
                            day:    event.day,
                            month:  event.monthShort,
                            title:  event.title,
                            place:  placeText(event),
                            isLast: index == events.count - 1
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(.white.opacity(0.82))
            .clipShape(.rect(cornerRadius: DT.cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: DT.cornerRadius)
                    .strokeBorder(.white.opacity(0.75), lineWidth: 0.5)
            }
            .shadow(color: .black.opacity(0.06), radius: 7, x: 0, y: 2)
            .padding(.horizontal, DT.padding)
            .padding(.vertical, 12)
            .padding(.bottom, 100)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - States

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView().scaleEffect(1.2)
            Text("Caricamento eventi…")
                .font(.system(size: 15))
                .foregroundStyle(.brandGray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 40))
                .foregroundStyle(.brandGrayLight)
            Text(message)
                .font(.system(size: 15))
                .foregroundStyle(.brandGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button("Riprova") { Task { await store.refresh() } }
                .buttonStyle(.borderedProminent)
                .tint(.brandRed)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar")
                .font(.system(size: 40))
                .foregroundStyle(.brandGrayLight)
            Text("Nessun evento in programma.")
                .font(.system(size: 15))
                .foregroundStyle(.brandGray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func placeText(_ event: Event) -> String {
        var parts: [String] = []
        if !event.location.isEmpty { parts.append(event.location) }
        if !event.time.isEmpty     { parts.append("ore \(event.time)") }
        return parts.joined(separator: " · ")
    }
}

#Preview {
    NavigationStack {
        EventiView()
            .navigationTitle("Eventi")
    }
    .environment(EventStore(service: StubEventService()))
}
