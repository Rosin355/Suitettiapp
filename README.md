# Ditelo sui Tetti — iOS App

Native iOS app for [Ditelo sui Tetti](https://comitaticivici.it), a civic editorial platform promoting active citizenship in Italy.

---

## Current Version

**v0.6.0** — Event Detail View & Calendar Integration  
*Last updated: 21 May 2026*

---

## Changelog

### v0.6.0 — Event Detail View & Calendar Integration (21 May 2026)
- `Event` UI model — id, title, slug, type, day, monthShort, fullDate, time, location, description, link, imageURL, rawDate, isUpcoming
- `EventDateParser` — parses `YYYY-MM-DD` date strings and flexible time strings to display strings and `Date` values; locale-aware Italian formatting; no force-unwraps
- `EventServiceProtocol` — `StubEventService` (fixtures) and `LiveEventService` (same API endpoint)
- `EventStore` — `@MainActor @Observable`; exposes `upcomingEvents` sorted ascending by date
- `EventDetailView` — immersive hero (RemoteImageView, branded purple fallback), floating dark-circle back/share buttons, "Quando" + "Dove" info cards (Dove is tappable → opens Apple Maps), HTML description, "Aggiungi al calendario" CTA, "Apri evento" external link
- `EventInfoCard` — reusable card row with icon tile, heading label, primary + secondary lines, optional tap action with arrow indicator
- `EventiView` — loading/error/empty/list states, pull-to-refresh, NavigationLink → EventDetailView; sorted by date ascending
- `EventCalendarService` — `@MainActor` singleton; `EKEventStore.requestFullAccessToEvents()` (iOS 17+); all-day event if time is empty, 2-hour timed event otherwise; graceful error handling; Settings deep-link on permission denied
- `MapsLauncher` — opens Apple Maps via `maps.apple.com/?q=` URL scheme; percent-encodes the location string
- `HomeEventsSection` — wired to real `EventStore` data; shows first 3 upcoming events; NavigationLink rows; "Tutti →" navigates to `EventiView`
- `EventStore` + `ArticleStore` loaded concurrently at app launch via `async let`
- ⚠️ **Required**: add `NSCalendarsFullAccessUsageDescription` to Info.plist via Xcode → Target → Info tab

### v0.5.0 — Document Detail View & PDF Reader (21 May 2026)
- `Document` UI model — id, title, slug, type, category, description, url, uploadedAt, updatedAt, syncVersion
- `DocumentDTO` expanded with full backend fields (`tipo`, `categoria`, `descrizione`, `url`, `dataCaricamento`)
- `DocumentServiceProtocol` — `StubDocumentService` (fixtures) and `LiveDocumentService` (real API, same endpoint as articles)
- `DocumentStore` — `@MainActor @Observable`, mirrors `ArticleStore` pattern with load/refresh/error states
- `PDFDownloadService` — `actor`; downloads remote PDF to `temporaryDirectory`, validates HTTP status + MIME type, deduplicates concurrent requests for the same URL via in-flight task cache
- `PDFKitView` — `UIViewRepresentable` wrapping `PDFView`; single-page-continuous vertical scrolling, auto-scales, pinch-zoom supported natively
- `PDFReaderView` — downloads PDF on appear, loading/error/retry states, `ShareLink` for local file in toolbar
- `DocumentDetailView` — type/category chips, metadata card (uploaded date, category, type), HTML-decoded description, "Leggi PDF" primary CTA (→ `PDFReaderView`), "Apri esternamente" + share secondary CTAs; graceful "PDF non disponibile" state when url is nil
- `DocumentListRow` — doc icon tile, title, type + date, chevron; follows `ArticleListRow` pattern
- `DocumentiView` — loading/error/empty/list states, pull-to-refresh, `NavigationLink → DocumentDetailView`
- `DocumentStore` injected at app root; `DocumentiView` available as screen for future tab navigation
- `Document.all` fixture data added to `PreviewData.swift`

### v0.4.0 — Article Detail View (21 May 2026)
- `ArticleDetailView` — full-bleed hero image (400 pt), dark gradient overlay, title + category chip over image
- Floating glass back button (`@Environment(\.dismiss)`) and `ShareLink` share button; both use `.glassEffect(.regular.interactive(), in: .circle)`
- System navigation bar hidden; custom floating controls replace it
- `RemoteImageView` — reusable `AsyncImage` wrapper with `ProgressView` while loading, branded gradient fallback on error or missing URL
- `HTMLTextFormatter.plainText(from:)` — strips HTML tags, decodes common entities (including Italian accented characters), collapses blank lines
- `Article.body` field added (mapped from `contenuto` DTO field)
- Read-time calculation updated: body word count at 200 wpm (was excerpt at 40 wpm)
- `FeaturedArticleCard` and `ArticleListRow` both use `RemoteImageView`; gradient fallback via `article.thumbnailColors`
- `HomeFeaturedArticlesSection` — `NavigationLink → ArticleDetailView` (was tab-switch button)
- `ArticlesListSection` — each row wrapped in `NavigationLink → ArticleDetailView`

### v0.3.0 — Live Backend Integration (21 May 2026)
- Connected to live `sync-editorial` Supabase edge function via `APIClient`
- Created `EditorialSyncResponseDTO`, `ArticleDTO`, `EventDTO`, `DocumentDTO`
- Activated `LiveEditorialService` with full `ArticleDTO → Article` mapping:
  - Deterministic palette colors per article (UUID-based, 5-color set)
  - Sentence-case conversion for ALL CAPS server titles
  - Italian locale date formatting (`d MMM`, `d MMM yyyy`)
  - Read-time calculated from excerpt word count
- Fixed ISO 8601 fractional-seconds crash in `JSONDecoder` (`updated_at` uses microseconds)
- `ArticleStore` promoted to `@MainActor` with `isRefreshing`, `errorMessage`, computed `categories`
- `ArticoliView` wired to live store: loading state, error state with retry, empty state, pull-to-refresh
- `HomeFeaturedArticlesSection` reads from store (hides when no articles)
- `ArticleStore` injected at app root via `.environment(store)`
- Previews use `StubEditorialService` for deterministic fixture data

### v0.2.0 — Architecture & Scroll-Reactive Navigation (19–20 May 2026)
- Full project restructure: 8 flat files → 30 micro-files across 12 feature folders
- `AppEnvironment` configuration layer with xcconfig pipeline (`Debug.xcconfig`, `Release.xcconfig`, `Secrets.xcconfig` placeholder)
- `APIClient` thin URLSession wrapper; `EditorialServiceProtocol` with stub/live implementations
- `ArticleStore` (`@Observable`) as central state container
- Scroll-reactive `HomeTopBar`: transparent over red hero → `.ultraThinMaterial` + title when scrolled past 220 pt
- `onScrollGeometryChange` (iOS 18+) for efficient scroll tracking
- Hardcoded URLs removed from views; `AppEnvironment.websiteURL` used in `SupportActionsSection`

### v0.1.0 — Initial UI Build (19 May 2026)
- 3-tab app: Home, Articoli, Sostieni
- `HomeView`: hero section, ticker, featured articles, events, quote, CTA card
- `ArticoliView`: filter bar, featured card, article list rows
- `SosteniView`: support hero, ways-to-help cards, copy-link, social share buttons
- Liquid Glass design system: brand colors, spacing tokens (`DT`), `GCard`, `CategoryChip`
- iOS 26 Tab API, `.glassEffect` buttons in navigation bar

---

## Product Requirements Document (PRD)

### Vision
Ditelo sui Tetti is the iOS companion to an Italian civic editorial platform. The app must feel like a trusted civic newspaper — editorial, trustworthy, fast — while delivering a modern iOS 26 / Liquid Glass aesthetic.

### Target Users
Italian citizens interested in civic participation, local governance, and community initiatives. Primary demographic: 25–55, iOS-first.

### Core Features (v1.0 scope)

| Feature | Status |
|---|---|
| Home feed with hero, featured articles, upcoming events | ✅ Done |
| Article list with category filter | ✅ Done |
| Live sync from `sync-editorial` backend | ✅ Done |
| Pull-to-refresh | ✅ Done |
| Support / Sostieni screen | ✅ Done |
| Article detail view | ✅ Done |
| Document detail view + PDF reader | ✅ Done |
| Event detail view + calendar save | ✅ Done |
| Delta sync (since timestamp) | 🔲 Next |
| Push notifications | 🔲 Backlog |
| Offline reading (SwiftData cache) | 🔲 Backlog |
| Authentication / user accounts | 🔲 Backlog |

### Design Principles
- **Content first** — chrome is invisible; content leads
- **iOS 26 / Liquid Glass** — `.ultraThinMaterial`, floating controls, layered depth
- **Accessibility always wins** — Dynamic Type, VoiceOver, 44×44 pt tap targets, reduced motion
- **Restrained glass** — blur never reduces legibility; long text on solid/near-solid backgrounds

### Backend Contract
- **Full sync:** `GET https://kbswgeliohnpwopzzzpc.supabase.co/functions/v1/sync-editorial`
- **Delta sync:** same endpoint + `?since=<ISO8601 timestamp>`
- **Auth:** none required for v1 (endpoint is public, filtered server-side)
- **Response shape:** `{ server_time, articles[], events[], documents[] }`
- **Date fields:** `updated_at` uses fractional ISO 8601; `data_evento` (events) is date-only `YYYY-MM-DD`

---

## Architecture

```
DiteloSuiTetti/
├── App/
│   └── AppTab.swift                  # Tab enum (home, articoli, sostieni)
├── Configuration/
│   └── AppEnvironment.swift          # Central URL/endpoint config; reads xcconfig or falls back
├── Network/
│   └── APIClient.swift               # URLSession wrapper; shared JSONDecoder with fractional-seconds support
├── Services/
│   └── EditorialService.swift        # EditorialServiceProtocol, StubEditorialService, LiveEditorialService
│                                     # + ArticleDTO → Article mapping (palette, dates, title casing)
├── Stores/
│   └── ArticleStore.swift            # @MainActor @Observable; articles, isLoading, isRefreshing, errorMessage
├── Models/
│   ├── Article.swift                 # UI model (id, slug, category, colors, title, date, readTime, excerpt, imageURL)
│   ├── ArticleDTO.swift              # Decodable DTO from backend
│   ├── EventDTO.swift                # Decodable DTO (dataEvento: String — date-only field)
│   ├── DocumentDTO.swift             # Decodable DTO (placeholder, backend returns 0 docs currently)
│   └── EditorialSyncResponseDTO.swift # Top-level response envelope
├── Fixtures/
│   └── PreviewData.swift             # Article.all static fixtures for SwiftUI previews
├── Design/
│   ├── AppColors.swift               # Brand color extensions on ShapeStyle/Color
│   ├── AppSpacing.swift              # DT spacing/corner-radius tokens
│   ├── AppShadows.swift              # Shadow presets
│   └── AppTypography.swift           # Font helpers
├── Components/
│   ├── Cards/
│   │   ├── GCard.swift               # Generic glass card container
│   │   └── FeaturedArticleCard.swift # Horizontal-scroll article card (RemoteImageView)
│   ├── Rows/
│   │   └── ArticleListRow.swift      # Article list row with thumbnail (RemoteImageView)
│   ├── Chips/
│   │   └── CategoryChip.swift        # Pill-shaped category label
│   ├── Common/
│   │   └── RemoteImageView.swift     # AsyncImage wrapper; branded gradient fallback
│   ├── Headers/
│   │   ├── HomeTopBar.swift          # Scroll-reactive floating nav bar
│   │   └── SectionHeader.swift       # Section title + optional action link
│   └── Ticker/
│       └── TickerView.swift          # Auto-scrolling news ticker
├── Screens/
│   ├── Home/
│   │   ├── HomeView.swift            # Root home screen; scroll tracking
│   │   ├── HomeHeroSection.swift     # Full-bleed red hero with app name + tagline
│   │   ├── HomeStatsStrip.swift      # Stats row (articles, events, signatures)
│   │   ├── HomeFeaturedArticlesSection.swift  # Horizontal scroll, 3 featured cards
│   │   └── HomeEventsSection.swift   # Upcoming events list
│   ├── Articles/
│   │   ├── ArticoliView.swift        # Article browser; loading/error/empty states; pull-to-refresh
│   │   ├── ArticlesFilterBar.swift   # Category filter pill bar
│   │   ├── ArticlesListSection.swift # Featured card + paginated article list; NavigationLink rows
│   │   └── ArticleDetailView.swift   # Full editorial detail; hero image, body text, glass controls
│   └── Support/
│       ├── SosteniView.swift         # Support screen root
│       ├── SupportHeroSection.swift  # Hero with donation prompt
│       └── SupportActionsSection.swift  # Ways to help, copy-link, social share
├── Utilities/
│   ├── HTMLTextFormatter.swift       # Strips HTML tags, decodes entities → plain String
│   ├── DateFormatting.swift
│   └── ViewModifiers.swift
├── ContentView.swift                 # TabView root; injects ArticleStore environment value
└── DiteloSuiTettiApp.swift           # @main; creates ArticleStore, injects env, triggers load()

Config/                               # Build configuration (project root)
├── Debug.xcconfig
├── Release.xcconfig
└── Secrets.xcconfig                  # ⚠️ NOT committed — placeholder only
```

### Data Flow

```
DiteloSuiTettiApp
  └── ArticleStore (@MainActor @Observable)
        └── LiveEditorialService
              └── APIClient.fetch(AppEnvironment.syncEditorialEndpoint)
                    └── JSONDecoder.editorial (snakeCase + fractional ISO8601)
                          └── EditorialSyncResponseDTO → [ArticleDTO] → [Article]

SwiftUI Environment
  ContentView
    ├── HomeView → HomeFeaturedArticlesSection reads @Environment(ArticleStore.self)
    └── ArticoliView reads @Environment(ArticleStore.self)
```

### Key Technical Decisions

| Decision | Rationale |
|---|---|
| `@Observable` + `@MainActor` on `ArticleStore` | UI-safe property updates without `DispatchQueue.main`; no `@Published` boilerplate |
| URLSession (not Supabase SDK) | Minimal dependencies; endpoint is public; SDK adds ~5 MB for zero benefit at this stage |
| Custom ISO 8601 decoder | Server returns fractional microseconds in `updated_at`; Swift's `.iso8601` strategy crashes on them |
| `dataEvento: String` in `EventDTO` | Server sends date-only `YYYY-MM-DD`; no standard formatter handles it — decode raw and parse in UI layer |
| Deterministic palette from UUID byte | All live articles share `categoria = "Articoli"`, so pure category-based coloring produces a monochrome list |
| Sentence-case mapping in service layer | Server titles arrive ALL CAPS — normalized once at the boundary, not in every view |
| Separate DTO ↔ UI models | DTOs are thin Decodable structs; UI models carry derived SwiftUI types (`Color`) that can't be `Codable` |

---

## Development Setup

### Requirements
- Xcode 26.3+
- iOS 26.2+ simulator or device
- No additional dependencies — pure SwiftUI + URLSession

### Clone & Run
```bash
git clone https://github.com/Rosin355/Suitettiapp.git
cd Suitettiapp
open DiteloSuiTetti.xcodeproj
```

Select the `DiteloSuiTetti` scheme, choose an iOS 26 simulator, and press Run. The app fetches live data from the public `sync-editorial` endpoint on first launch.

### Xcconfig (optional)
The app works out of the box with hardcoded fallback URLs in `AppEnvironment.swift`. To use xcconfig:
1. Xcode → Project → Info → Configurations → assign `Config/Debug.xcconfig` and `Config/Release.xcconfig`
2. Add `API_BASE_URL` and `WEBSITE_URL` keys to `Info.plist` as `$(API_BASE_URL)` / `$(WEBSITE_URL)`

### Secrets
Copy `Config/Secrets.xcconfig` if you need to add a Supabase anon key in a future version. This file is gitignored.

---

## Contributing

This is a private civic project. Contact the maintainers via the Ditelo sui Tetti editorial team before opening pull requests.
