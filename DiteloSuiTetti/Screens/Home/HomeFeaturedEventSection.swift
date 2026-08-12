import SwiftUI

/// Renders the featured-event banner, or nothing at all.
///
/// The section owns no state of its own: it reads `EventStore.featuredEvent`, which is
/// recomputed from whatever the last sync returned. That is what makes the banner
/// disappear by itself when an editor clears the flag — there is nothing cached
/// separately that could keep it alive, and no empty placeholder is left behind.
struct HomeFeaturedEventSection: View {
    @Environment(EventStore.self) private var store

    var body: some View {
        if let event = store.featuredEvent {
            HomeFeaturedEventCard(event: event)
                .padding(.horizontal, DT.padding)
                .padding(.top, 6)
                .padding(.bottom, 12)
                .appearAnimation(delay: 0.15)
        }
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            HomeFeaturedEventSection()
        }
        .background(Color.brandCream)
    }
    .environment(EventStore(service: StubEventService()))
}
