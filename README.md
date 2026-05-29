# Ditelo sui Tetti — iOS App

Native iOS app for [Ditelo sui Tetti](https://comitaticivici.it), a civic editorial platform promoting active citizenship in Italy.

---

## Current Version

**v2.0.0** — Tab restructure, Android handoff, document decoder hardening  
*Last updated: 29 May 2026*

---

## Android / Kotlin Handoff

Documentation for rebuilding this app in Kotlin / Jetpack Compose:

| Document | Purpose |
|----------|---------|
| [docs/ANDROID_HANDOFF.md](docs/ANDROID_HANDOFF.md) | App architecture, screen flows, iOS→Android technology mapping |
| [docs/API_CONTRACT.md](docs/API_CONTRACT.md) | Supabase API endpoints, field definitions, decoding resilience rules |
| [docs/ANDROID_IMPLEMENTATION_PLAN.md](docs/ANDROID_IMPLEMENTATION_PLAN.md) | Phase-by-phase Kotlin build plan (Phases 1–11) |

Key notes for the Android developer:
- Documents must be decoded **per-item** (one bad record must not zero the whole array)
- Documents with a missing PDF URL **must still appear** in the list ("PDF non disponibile")
- All events may be past — Home shows only upcoming events; empty state is valid
- The Documenti tab is a first-class tab with its own fetching and PDF viewer
- The Chi siamo tab contains: support CTA, Privacy Policy, Terms, notification settings, rate-app, version/build, and Digital Yogin srl attribution

---

## Changelog

### v2.0.0 — Tab Restructure & Document Decoder Hardening (29 May 2026)
- Tab bar restructured: **Home**, **Articoli**, **Documenti**, **Chi siamo** (Sostieni removed as a tab)
- `AboutView` (Chi siamo) — intro, mission cards, support CTA, settings rows (Privacy, Terms, Notifications, Rate app), developer info
- `DocumentDTO` decoder hardened: only `id` is required; `tipo`, `categoria`, `descrizione`, `syncVersion` default gracefully; accepts multiple field name variants for URL (`url` / `file_url` / `document_url` / `link`) and title (`titolo` / `title`)
- `EditorialSyncResponseDTO` — per-item lossy decoding via `Lossy<T>` wrapper; one bad document no longer zeros the entire `documents` array; failed items are logged individually
- `HomeFeaturedArticlesSection` — replaced horizontal card carousel with vertical `ArticleListRow` list (max 5 articles); "Tutti" → "Vedi tutti"
- Home scroll fixed: 130dp bottom clearance ensures last card scrolls above floating tab bar
- `HeroTickerView` — removed `edgeCover` gradient overlay that caused white premultiplied-alpha glow bands on physical devices
- `InAppWebView` + `WebPageView` — WKWebView-backed in-nav web pages for legal screens
- `AppEnvironment` — added `privacyPolicyURL` and `termsURL`
- Deep link routing for documents now switches to `.documenti` tab (was `.home`)
- Android/Kotlin handoff documentation added to `docs/`

## Changelog (prior)

### v1.7.0 — APNs Token Registration (27 May 2026)
- APNs device token registration wired end-to-end: iOS calls `UIApplication.shared.registerForRemoteNotifications()` after notification permission is granted (new users) and on every app launch when permission is already active (existing users)
- `AppDelegate.application(_:didRegisterForRemoteNotificationsWithDeviceToken:)` — converts raw `Data` token to lowercase hex string; logs token prefix in DEBUG; forwards to `PushTokenRegistrationService`
- `AppDelegate.application(_:didFailToRegisterForRemoteNotificationsWithError:)` — logs failure in DEBUG builds
- `PushTokenRegistrationService` — `@MainActor` singleton; POSTs device token, platform, environment (`sandbox` in DEBUG/Xcode, `production` in Release/TestFlight), bundle ID, app version, and build number to the `register-push-token` Edge Function; deduplicates via `UserDefaults` so the network call is skipped when the token is unchanged since last successful registration
- `push_device_tokens` Supabase table — `device_token unique`, `platform`, `environment check (sandbox|production)`, `bundle_id`, `app_version`, `build_number`, `is_enabled`, `last_seen_at`, `created_at`, `updated_at`; RLS enabled with no anon access; all writes go through Edge Function service role
- `register-push-token` Supabase Edge Function — validates payload fields; upserts by `device_token` conflict target (insert on first registration, update `environment`, `bundle_id`, `app_version`, `build_number`, `is_enabled=true`, `last_seen_at`, `updated_at` on subsequent calls); `SUPABASE_SERVICE_ROLE_KEY` used server-side only
- Remote push sending is not implemented in this version

### v1.6.1 — Local Notifications Hardening (26 May 2026)
- `LocalNotificationManager` — notification IDs are now marked as sent only after `center.add(_:)` succeeds; previously IDs were persisted before the OS confirmed scheduling, which could silently suppress future attempts for the same content item
- `LocalNotificationManager` — `schedule()` now uses explicit `do/catch`; scheduling failures are logged in `DEBUG` builds (`▶ LocalNotificationManager: failed to schedule '<id>' — <reason>`) instead of being silently swallowed by `try?`
- `LocalNotificationManager.canScheduleNotifications(status:)` — scheduling now permits `.authorized`, `.provisional`, and `.ephemeral` authorization statuses; previously only `.authorized` was accepted, which blocked provisional grants (common on first install)
- Onboarding gate — `.provisional` is now treated as an already-answered permission state; tapping "Inizia →" skips `NotificationPermissionView` and enters `ContentView` directly when status is `.authorized`, `.provisional`, `.denied`, or `.ephemeral`

### v1.6.0 — Local Notifications MVP (26 May 2026)
- `NotificationPermissionView` — custom permission pre-prompt shown between onboarding and ContentView; cream gradient background, `bell.badge.fill` icon, 3 feature cards (articles/events/documents), "Abilita notifiche" primary CTA, "Non ora" secondary; triggers the system permission prompt only when user confirms; skipped if permission already answered
- `LocalNotificationManager` — `@MainActor` singleton; checks `UNAuthorizationStatus` before scheduling; deterministic notification IDs (`article.<uuid>`, `event.<uuid>`, `document.<uuid>`); `sentLocalNotificationIDs` in UserDefaults prevents duplicate notifications; `UNTimeIntervalNotificationTrigger(timeInterval: 1)` for immediate local delivery
- `NewContentDetector` — compares previous vs fresh `EditorialSyncPayload` by ID set difference; returns max 1 new article, 1 new event, 1 new document per sync; no notifications on first install (no previous cache = no comparison)
- `AppNotificationDelegate` — `AppDelegate` + `NotificationCenterDelegate` wiring; sets `UNUserNotificationCenterDelegate` at launch; foreground: shows banner + sound; tap: parses `userInfo` into `NotificationDeepLink` and calls `AppDeepLinkRouter.shared.handle(_:)`
- `NotificationDeepLink` — `struct` with `id: UUID`, `contentType`, `slug`; `init?(userInfo:)` for parsing; `userInfo: [String: Any]` for scheduling; APNs-ready payload structure
- `AppDeepLinkRouter` — `@MainActor @Observable` singleton; `pendingNotificationLink` observed by ContentView; `contentDidLoad` flag coordinates cold-launch deep link resolution after stores populate
- ContentView navigation — `pendingArticle/Event/Document` state; `.navigationDestination(isPresented:)` per tab; `resolveDeepLink` switches tab + looks up content by id then slug; graceful fallback to tab switch if content not found
- `SosteniView` — "Impostazioni" section with `NotificationStatusSection`: shows current auth status ("Abilitate" / "Non abilitate" / "Non ancora richieste"), "Apri" button opens Settings if denied
- Onboarding gate updated: after "Inizia →", checks existing auth status; if already answered, enters ContentView directly; otherwise shows `NotificationPermissionView`

### v1.5.1 — Onboarding Visual Alignment & Animated Bokeh (26 May 2026)
- Slides reordered to match reference: **Slide 0** = cream mission, **Slide 1** = red brand hero, **Slide 2** = dark festival
- Slide 2 content replaced: referendum copy → **Sui Tetti Festival 2026** (badge, title, Georgia italic subtitle, body, closing "Ti aspettiamo. ♡")
- `OnboardingBokehBackground` — new reusable component in `Components/Effects/`; `enum OnboardingBokehTheme { case cream, red, dark }` controls per-slide circle palettes; dark theme uses `.blendMode(.screen)` for luminous festival glow; cream theme uses subtle warm glows that stay behind pillar cards; same `GeometryReader` + relative positioning + `withAnimation` idiom as `BokehCirclesBackground`; `static let debugMode = false` flip for dev verification
- All 3 onboarding slides: static `GeometryReader` orbs removed, replaced with `OnboardingBokehBackground(theme:)` — circles now animate on all slides
- `OnboardingBokehTuning` constants (×1.45 opacity, ×1.65 movement, ×0.75 blur) ensure bokeh visibility on OLED devices
- Reduce Motion: all themes render static circles at boosted opacity (no movement) when system Reduce Motion is enabled
- Per-slide dot/CTA/skip styling updated: dots brandRed on cream (slide 0), white on red/dark; CTA frosted glass on red slide, solid brandRed on cream and dark; skip button gray on cream, white-translucent on red
- Haptic feedback on "Avanti" / "Inizia" taps via `.sensoryFeedback(.selection, trigger:)`
- Slide content appear animation: `.easeOut` fade + 16 pt y-offset lift on each slide's first appearance

### v1.5.0 — Onboarding Screen (26 May 2026)
- 3-slide onboarding (red hero → cream mission → dark referendum) with `TabView(.page)` paging, frosted glass CTA, expanding dot indicator, skip button
- `@AppStorage("hasSeenOnboarding")` gate in `DiteloSuiTettiApp` — first launch shows onboarding, subsequent launches go directly to `ContentView`; `.easeInOut(duration: 0.4)` cross-fade transition between states
- `OnboardingLogoIcon` — `Canvas`-drawn custom SVG logo mark used in the red hero slide

### v1.4.1 — Visual Polish & Micro-Interactions (26 May 2026)
- `BokehCirclesBackground` — fixed invisible bokeh circles in `HomeHeroSection`; root cause: absolute pixel offsets placed circles outside the ZStack bounds (clipped by `.clipped()`), opacity 0.05–0.16 was below the visual threshold on brand red, and blur 24–55 dissolved circles into noise; fixed with `GeometryReader` + relative positioning (`relX`/`relY` fractions), opacity raised to 0.13–0.22, blur reduced to 14–30
- `BokehCirclesBackground.debugMode` — `static let debugMode = false`; flip to `true` to render circles at 2.5× opacity with yellow `strokeBorder` outlines for dev verification; zero runtime cost when `false`
- `BokehCirclesBackground` Reduce Motion — when system "Reduce Motion" is enabled, circles render as static shapes at their base positions with no animation
- `PressableCardStyle` — `ButtonStyle` applying 0.98 scale spring on press for all `NavigationLink` cards across articles, events, documents, and home sections; disabled when Reduce Motion is on
- `AppearModifier` + `.appearAnimation(delay:)` — fade + 12 pt y-offset appear animation applied at section level (never per-row) to home sections, article/event/document lists; Reduce Motion aware
- `SkeletonLoadingList` — shimmer skeleton loading state replaces `ProgressView` in `ArticoliView`, `EventiView`, `DocumentiView`; shimmer driven by `LinearGradient` phase animation
- Haptic feedback — `.sensoryFeedback(.impact(weight: .light, intensity: 0.8))` on copy-link button in `SupportActionsSection`; `.sensoryFeedback(.success)` on calendar save in `EventDetailView`

### v1.3.0 — SwiftData Offline Cache (26 May 2026)
- `CachedArticle`, `CachedEvent`, `CachedDocument` — `@Model` classes persisting all editorial content to SwiftData; `Color` recomputed on load from `articleColorPalette` (not stored); `eventDescription`/`documentDescription` naming avoids NSObject `.description` collision
- `EditorialCacheRepository` — `@MainActor` self-contained `ModelContainer`; `loadPayload()` returns `EditorialSyncPayload?` (nil if cache empty); `clearAndReplace(with:)` batch-replaces all three entity types
- Cache-first launch — if cache exists: stores populate immediately with no spinner; network sync runs in background and silently replaces content; if network fails with cache present: non-blocking `offlineMessage` banner shown; if network fails with no cache: existing error state
- `offlineMessage: String?` — new property on `ArticleStore`, `EventStore`, `DocumentStore`; shown as a non-blocking `wifi.slash` banner below the offline condition; cleared on successful sync
- Offline banner — `ArticoliView`, `EventiView`, `DocumentiView` each show a non-blocking `wifi.slash` banner when `store.offlineMessage` is set
- `articleColorPalette` — extracted to `Utilities/ArticleColorPalette.swift`; shared between `ArticleMapper` and `CachedArticle.toArticle()`

### v1.2.0 — Shared Detail Layout (26 May 2026)
- `DetailHeroImage` — reusable full-bleed hero: `AsyncImage` with branded gradient fallback, configurable height, dark gradient overlay for text legibility; used by `ArticleDetailView` and `EventDetailView`
- `DetailTitleCard` — reusable floating title card: configurable label chip color, semibold serif title, clips to card shape with subtle shadow

### v1.0.0 — Shared Detail Hero Foundation (25 May 2026)
- Introduced shared `ZStack`-based hero layout foundation reused across `ArticleDetailView`, `EventDetailView`, and `DocumentDetailView`

### v0.9.0 — APIClient Hardening (25 May 2026)
- `URLRequest` with 20 s timeout, `Accept: application/json`, `User-Agent: DiteloSuiTetti-iOS/1.0`
- 8 typed `APIError` cases with Italian `localizedDescription` strings: `invalidResponse`, `badStatus(code:message:)`, `emptyResponse`, `decodingFailed`, `transportFailed`, `timedOut`, `offline`, `cancelled`
- 2-retry exponential backoff (0.5 s → 1.0 s) for transient failures: 5xx, timeout, offline; no retry on 4xx, decoding errors, or cancellation
- `URLError` classified into `.offline` / `.timedOut` / `.cancelled` / `.transportFailed`
- Server error body decoded from JSON (`error`, `message`, `details` fields) or UTF-8 and surfaced in `badStatus` message
- Task cancellation respected at every await point — throws `.cancelled`, never retries
- `#if DEBUG` request/response/retry logging: `▶ GET …`, `← 200 (N bytes)`, `↺ retry N/2 in Xs`
- Public `APIClient.fetch(_:as:)` signature unchanged — zero call-site changes

### v0.8.0 — Central Editorial Sync Coordinator (25 May 2026)
- `EditorialSyncCoordinator` — single `sync-editorial` network request at launch; maps all three content types and returns `EditorialSyncPayload`; eliminates the previous 3 duplicate HTTP requests
- `EditorialSyncPayload` — lightweight value type carrying `[Article]`, `[Event]`, `[Document]`, `serverTime: Date`
- `ArticleMapper`, `EventMapper`, `DocumentMapper` — DTO→UI model mapping extracted from service files into dedicated `Mappers/` files as `internal extension` on DTO types; no mapping logic is duplicated
- `ArticleStore`, `EventStore`, `DocumentStore` — added `beginLoading()`, `replace(with:)`, `failedLoading(message:)` coordinator-support methods; existing `load()` / `refresh()` unchanged
- `EditorialService`, `EventService`, `DocumentService` — mapping blocks removed; stubs and live services unchanged
- `DiteloSuiTettiApp` — single `coordinator.syncAll()` call replaces three `async let` store loads; all stores show loading state immediately; error state distributed to all stores on failure
- Debug logging consolidated in coordinator: `▶ sync started`, `✓ sync succeeded` with counts, event bucket breakdown, `✗ sync failed`
- Pull-to-refresh continues to use individual store `refresh()` methods (3 separate requests on user action — acceptable; coordinator injection is a future improvement)

### v0.7.1 — Production-Readiness Configuration (25 May 2026)
- `DocumentStore.load()` added to concurrent app-launch task (was missing — Documenti tab always opened empty)
- `NSCalendarsFullAccessUsageDescription` added to generated Info.plist build settings (required for EventKit on iOS 17+; both Debug and Release configurations)
- `docs/APP_STORE_OWNERSHIP.md` — bundle ID, team ID, Digital Yogin publication strategy, App Store Transfer checklist, capabilities to avoid before transfer

### v0.7.0 — Event Parsing & Filtering Improvements (25 May 2026)
- `Event.isUpcoming` fixed — undated events (nil `rawDate`) now return `false` instead of `true`; previously they were silently bucketed as upcoming
- `Event.isPast` and `Event.isUndated` computed properties added
- `EventStore.pastEvents` — filtered descending by date; `EventStore.undatedEvents` — stable order
- `EventDateParser.parseDate` extended with fallback formats: `yyyy-MM-dd` (primary), ISO datetime with offset, ISO datetime fractional, `dd/MM/yyyy`
- `EventDateParser.parseTime` now strips `"ore "` prefix before parsing (common in Italian event data)
- `EventiView` — segmented filter (Prossimi / Passati / Tutti); smart empty state on "Prossimi" offers a direct switch to "Passati" when past events exist; all three buckets navigable to `EventDetailView`
- `HomeEventsSection` — always visible; gentle "Nessun evento in programma." text replaces the invisible empty section
- `#if DEBUG` logging in `EventService.toEvent()` (per-event parse failure) and `LiveEventService.fetchAll()` (totals: upcoming / past / undated counts)

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
| Event filtering (upcoming / past / all) | ✅ Done |
| Delta sync (since timestamp) | 🔲 Next |
| Push notifications | ✅ Done |
| Offline reading (SwiftData cache) | ✅ Done |
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

## Testing TODO

No test target exists yet. When one is added, `APIClient` unit tests should cover:

- `2xx` → decoding success, no retry
- `4xx` → `badStatus`, no retry
- `5xx` → `badStatus`, retried up to 2×
- Offline (`notConnectedToInternet`) → `.offline`, retried up to 2×
- Timeout (`URLError.timedOut`) → `.timedOut`, retried up to 2×
- Decoding failure → `.decodingFailed`, no retry
- Task cancellation → `.cancelled`, no retry, thrown immediately

---

## Contributing

This is a private civic project. Contact the maintainers via the Ditelo sui Tetti editorial team before opening pull requests.
