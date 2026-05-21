import SwiftUI

struct HomeEventsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "Prossimi eventi", action: "Tutti") {}

            GCard {
                VStack(spacing: 0) {
                    EventRow(day: "07", month: "GIU",
                             title: "Presidio civico — Milano",
                             place: "Piazza della Scala, ore 10:00")
                    EventRow(day: "10", month: "GIU",
                             title: "Assemblea nazionale — Roma",
                             place: "Via del Corso 42, ore 15:00",
                             isLast: true)
                }
            }
            .padding(.horizontal, DT.padding)
            .padding(.bottom, 12)
        }
    }
}
