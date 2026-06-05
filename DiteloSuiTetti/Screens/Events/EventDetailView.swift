import SwiftUI

struct EventDetailView: View {
    let event: Event

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var calendarError: CalendarSaveError?
    @State private var showCalendarError = false
    @State private var showCalendarSuccess = false

    // MARK: - Derived

    private var plainDescription: String {
        HTMLTextFormatter.plainText(from: event.description)
    }

    private var shareText: String {
        var lines = ["📅 \(event.title)"]
        var when = event.fullDate
        if !event.time.isEmpty { when += " · ore \(event.time)" }
        lines.append("Quando: \(when)")
        if !event.location.isEmpty { lines.append("Dove: \(event.location)") }
        if let link = event.link   { lines.append("Scopri di più: \(link.absoluteString)") }
        return lines.joined(separator: "\n")
    }

    private var heroColors: [Color] {
        [Color(red: 91/255, green: 82/255, blue: 208/255),
         Color(red: 55/255, green: 48/255, blue: 155/255)]
    }

    private var eventTitle: String {
        TextNormalizer.singleLineClean(event.title)
    }

    private var eventLabel: String {
        event.type.isEmpty ? "Evento" : event.type
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroSection
                titleCardSection
                contentSection
            }
            .containerRelativeFrame(.horizontal)
        }
        .scrollIndicators(.hidden)
        .ignoresSafeArea(edges: .top)
        .background(.brandCream)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: 16)
        }
        .overlay(alignment: .top) {
            HStack(alignment: .top) {
                backButton
                Spacer()
                shareButton
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .safeAreaPadding(.top)
        }
        .alert("Evento salvato", isPresented: $showCalendarSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("\"\(event.title)\" è stato aggiunto al tuo calendario.")
        }
        .alert("Errore calendario", isPresented: $showCalendarError) {
            Button("OK", role: .cancel) {}
            if case .accessDenied = calendarError {
                Button("Impostazioni") {
                    openURL(URL(string: "app-settings:")!)
                }
            }
        } message: {
            Text(calendarError?.errorDescription ?? "Impossibile salvare l'evento.")
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        DetailHeroImage(
            imageURL: event.imageURL,
            fallbackColors: heroColors,
            height: 340
        )
    }

    // MARK: - Title card

    private var titleCardSection: some View {
        DetailTitleCard(
            label: eventLabel,
            labelColor: Color(red: 91/255, green: 82/255, blue: 208/255),
            title: eventTitle
        )
    }

    // MARK: - Content

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            infoCards
                .padding(.top, 20)
                .padding(.horizontal, 24)

            if !plainDescription.isEmpty {
                Rectangle()
                    .fill(.brandSep)
                    .frame(height: 1)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                Text(plainDescription)
                    .font(.system(size: 17))
                    .foregroundStyle(.brandBlack)
                    .lineSpacing(7)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
            }

            actionButtons
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 24)

            relatedDocumentsSection
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            NSLog("[EventDetailView] opened slug '%@' relatedDocs: %d",
                  event.slug, event.relatedDocuments.count)
        }
    }

    @ViewBuilder
    private var relatedDocumentsSection: some View {
        if !event.relatedDocuments.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                Rectangle()
                    .fill(.brandSep)
                    .frame(height: 1)
                    .padding(.horizontal, 24)

                Text("Documenti dell'evento")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.brandGray)
                    .textCase(.uppercase)
                    .kerning(0.5)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 12)

                VStack(spacing: 8) {
                    ForEach(event.relatedDocuments) { doc in
                        LinkedDocumentCard(document: doc)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 100)
            }
        } else {
            Color.clear.frame(height: 100).allowsHitTesting(false)
        }
    }

    // MARK: - Info cards (Quando / Dove)

    private var infoCards: some View {
        VStack(spacing: 0) {
            EventInfoCard(
                icon: "calendar",
                heading: "Quando",
                primaryLine: event.fullDate,
                secondaryLine: event.time.isEmpty ? "" : "ore \(event.time)"
            )
            .accessibilityLabel("Quando: \(event.fullDate)\(event.time.isEmpty ? "" : ", ore \(event.time)")")

            if !event.location.isEmpty {
                Divider().padding(.horizontal, 16)
                EventInfoCard(
                    icon: "mappin.and.ellipse",
                    heading: "Dove",
                    primaryLine: event.location,
                    action: { MapsLauncher.open(location: event.location) }
                )
                .accessibilityLabel("Dove: \(event.location). Tocca per aprire in Maps.")
                .accessibilityHint("Apre Apple Maps")
                .accessibilityAddTraits(.isButton)
            }
        }
        .background(.white.opacity(0.82))
        .clipShape(.rect(cornerRadius: DT.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: DT.cornerRadius)
                .strokeBorder(.white.opacity(0.75), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    // MARK: - Action buttons

    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                Task { await addToCalendar() }
            } label: {
                Label("Aggiungi al calendario", systemImage: "calendar.badge.plus")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .tint(.brandRed)
            .controlSize(.large)
            .accessibilityLabel("Aggiungi questo evento al tuo calendario")
            .sensoryFeedback(.success, trigger: showCalendarSuccess)

            if let link = event.link {
                Link(destination: link) {
                    Label("Apri evento", systemImage: "arrow.up.right.square")
                        .font(.system(size: 15, weight: .medium))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.brandGray)
                .controlSize(.large)
                .accessibilityLabel("Apri la pagina dell'evento nel browser")
            }
        }
    }

    // MARK: - Floating buttons

    private var backButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(.black.opacity(0.35))
                        .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 2)
                )
        }
        .accessibilityLabel("Torna indietro")
    }

    private var shareButton: some View {
        ShareLink(item: shareText) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(.black.opacity(0.35))
                        .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 2)
                )
        }
        .accessibilityLabel("Condividi evento")
    }

    // MARK: - Calendar

    private func addToCalendar() async {
        do {
            try await EventCalendarService.shared.saveEvent(event)
            showCalendarSuccess = true
        } catch let error as CalendarSaveError {
            calendarError = error
            showCalendarError = true
        } catch {
            calendarError = .saveFailed(error)
            showCalendarError = true
        }
    }
}

#Preview("Short title") {
    NavigationStack {
        EventDetailView(event: Event.all[0])
    }
    .environment(EventStore(service: StubEventService()))
}

#Preview("Long title") {
    NavigationStack {
        EventDetailView(event: Event(
            id: UUID(),
            title: "SUI TETTI del MEETING 2025, insieme con mattoni nuovi per un futuro più solido e condiviso!",
            slug: "meeting-2025",
            type: "Meeting",
            day: "20",
            monthShort: "AGO",
            fullDate: "20 agosto 2025",
            time: "09:00",
            location: "Rimini Fiera",
            description: "",
            link: nil,
            imageURL: nil,
            rawDate: nil,
            updatedAt: Date(),
            syncVersion: 1
        ))
    }
    .environment(EventStore(service: StubEventService()))
}
