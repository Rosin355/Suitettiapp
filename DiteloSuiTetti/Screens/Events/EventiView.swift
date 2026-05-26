import SwiftUI

private enum EventFilter: String, CaseIterable {
    case upcoming = "Prossimi"
    case past     = "Passati"
    case all      = "Tutti"
}

struct EventiView: View {
    @Environment(EventStore.self) private var store
    @State private var filter: EventFilter = .upcoming

    private var filteredEvents: [Event] {
        switch filter {
        case .upcoming: return store.upcomingEvents
        case .past:     return store.pastEvents
        case .all:      return store.upcomingEvents + store.pastEvents + store.undatedEvents
        }
    }

    var body: some View {
        Group {
            if store.isLoading {
                loadingView
            } else if let message = store.errorMessage {
                errorView(message: message)
            } else {
                VStack(spacing: 0) {
                    filterBar
                    if filteredEvents.isEmpty {
                        emptyView
                    } else {
                        eventList
                    }
                }
                .appearAnimation()
            }
        }
        .background(.brandCream)
        .task { await store.load() }
        .refreshable { await store.refresh() }
    }

    // MARK: - Filter bar

    private var filterBar: some View {
        Picker("Filtro", selection: $filter) {
            ForEach(EventFilter.allCases, id: \.self) { f in
                Text(f.rawValue).tag(f)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, DT.padding)
        .padding(.vertical, 12)
    }

    // MARK: - List

    private var eventList: some View {
        ScrollView {
            VStack(spacing: 0) {
                if let msg = store.offlineMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "wifi.slash").font(.system(size: 12))
                        Text(msg).font(.system(size: 13))
                    }
                    .foregroundStyle(.brandGray)
                    .padding(.horizontal, DT.padding)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                }

                Rectangle()
                    .fill(.white.opacity(0.8))
                    .frame(height: 1)

                ForEach(Array(filteredEvents.enumerated()), id: \.element.id) { index, event in
                    NavigationLink(destination: EventDetailView(event: event)) {
                        EventRow(
                            day:    event.day,
                            month:  event.monthShort,
                            title:  event.title,
                            place:  placeText(event),
                            isLast: index == filteredEvents.count - 1
                        )
                    }
                    .buttonStyle(PressableCardStyle())
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
        ScrollView {
            SkeletonLoadingList()
                .padding(.top, 16)
        }
        .scrollIndicators(.hidden)
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
            if filter == .upcoming && !store.pastEvents.isEmpty {
                Text("Nessun evento futuro.")
                    .font(.system(size: 15))
                    .foregroundStyle(.brandGray)
                Button("Consulta gli eventi passati") {
                    filter = .past
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.brandRed)
                .padding(.top, 4)
            } else {
                Text("Nessun evento in programma.")
                    .font(.system(size: 15))
                    .foregroundStyle(.brandGray)
            }
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
