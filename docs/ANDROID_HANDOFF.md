# Android / Kotlin Handoff — Ditelo sui Tetti

Complete architectural reference for rebuilding the Ditelo sui Tetti iOS app in Kotlin / Jetpack Compose.

---

## 1. App Purpose

Ditelo sui Tetti is a civic editorial platform for Italian citizens who support traditional family values, educational freedom, subsidiarity, and the common good. The app provides:

- A curated editorial feed (articles, events, documents)
- PDF document viewer
- Event calendar integration
- Push notifications for new content
- Offline-first experience (cache before network)

The app is Italian-language. All UI strings, field names in the database, and category labels are in Italian. Some backend field names have Italian variants (`titolo`, `categoria`, `tipo`, `descrizione`); the Android implementation must handle both Italian and English field name variants for documents (see API_CONTRACT.md).

---

## 2. Tab Structure

The app has four tabs in a floating glass tab bar:

| Tab | Label | Icon | Screen |
|-----|-------|------|--------|
| 1 | Home | house | Feed, hero, featured articles, upcoming events |
| 2 | Articoli | doc.text | Full article list with category filter |
| 3 | Documenti | folder | Document list, PDF reader |
| 4 | Chi siamo | info.circle | About, support CTA, settings |

---

## 3. Launch and Onboarding Flow

```
App Launch
    │
    ├── hasSeenOnboarding == false
    │       │
    │       └── OnboardingView (3-slide pager)
    │               │
    │               └── User taps "Inizia →"
    │                       │
    │                       ├── notification permission already answered → ContentView
    │                       └── not answered → NotificationPermissionView
    │                               │
    │                               ├── "Abilita" → request permission → ContentView
    │                               └── "Non ora" → ContentView
    │
    └── hasSeenOnboarding == true → ContentView
```

**OnboardingView**: 3 slides using a paged `TabView`. Each slide has a full-bleed background (animated mesh gradient on the brand red slide), brand text, and a category-specific illustration.

**NotificationPermissionView**: Custom pre-prompt screen shown before the OS system dialog. Shows three feature cards explaining notification value. Only triggers the OS dialog if the user confirms.

**Android equivalent**: `SharedPreferences` boolean `hasSeenOnboarding`. Navigation graph with `OnboardingScreen → NotificationPromptScreen → MainScreen`.

---

## 4. Sync and Data Flow

### 4.1 Full sync on launch

```
ContentView.onAppear
    │
    ├── 1. Try to load SwiftData cache (EditorialCacheRepository.loadPayload)
    │       │
    │       ├── Cache exists → populate ArticleStore, EventStore, DocumentStore immediately (no spinner)
    │       └── Cache empty → begin loading state on all three stores
    │
    └── 2. Fire EditorialSyncCoordinator.syncAll() — always runs, regardless of cache
            │
            ├── GET /functions/v1/sync-editorial
            ├── Decode response → EditorialSyncResponseDTO
            ├── Map DTOs → domain models
            ├── Replace store contents
            ├── Write new payload to SwiftData cache
            └── Schedule local notifications for newly detected content
```

**Delta sync**: The endpoint accepts `?since=<ISO_DATE>` for incremental updates. The iOS app currently always does a full sync on launch. The delta endpoint is available for future use.

**Featured event**: no extra request. `is_home_featured` rides along on every event object in this
same payload, so the banner updates on the existing sync triggers. Do not add a dedicated
endpoint, a polling loop, or a new Edge Function — see `FEATURED_EVENT.md` §6.

### 4.2 Store architecture

Each content type has its own `@Observable @MainActor` store:

| Store | State |
|-------|-------|
| `ArticleStore` | articles, isLoading, isRefreshing, errorMessage, offlineMessage |
| `EventStore` | events, upcomingEvents (computed), isLoading, isRefreshing, errorMessage, offlineMessage |
| `DocumentStore` | documents, isLoading, isRefreshing, errorMessage, offlineMessage |

`upcomingEvents` is computed: `events.filter { $0.isUpcoming }.sorted(by: rawDate)`.

**Note**: At any given time, all events in the backend may be past events. The Home tab only shows upcoming events. The Articoli tab (events view, if present) shows all events sorted by date. Never crash or show an error if the upcoming list is empty — show an empty state.

### 4.3 Offline behaviour

- **Cache hit + network success**: content silently replaces cache, no user-visible disruption.
- **Cache hit + network failure**: `offlineMessage` banner shown non-blocking; existing content remains visible.
- **No cache + network failure**: error state with retry button.
- **No cache + network success**: full load from network.

**Android equivalent**: Repository pattern with Room as local source and Retrofit as remote source. The repository prefers Room data while the network call runs in the background.

---

## 5. Article Flow

```
ArticleStore.articles (all)
    │
    ├── Home → HomeFeaturedArticlesSection → first 5 articles → vertical list
    ├── Articoli tab → ArticoliView → full list with category filter bar
    └── ArticleListRow → NavigationLink → ArticleDetailView
```

**ArticleDetailView layout**:
- Full-bleed hero image (or branded gradient fallback) at top
- Floating back / share buttons over hero
- Title card below hero
- Article body (HTML-formatted text, stripped to plain text)
- Share button uses system share sheet

**Article body**: The `contenuto` field from the backend is HTML. The iOS app uses `HTMLTextFormatter.plainText(from:)` to strip tags and clean whitespace for display. Android should do equivalent HTML-to-string stripping (e.g., `Html.fromHtml()` or a custom parser).

---

## 6. Event Flow

```
EventStore.featuredEvent (derived: events.filter(isFeatured) → deterministic winner)
    │
    └── Home → HomeFeaturedEventSection → HomeFeaturedEventCard → EventDetailView

EventStore.upcomingEvents (filtered, upcoming only, minus the featured one)
    │
    └── Home → HomeEventsSection → first 3 upcoming events → cards

EventStore.events (all, sorted by date)
    └── EventiView / full events list (always includes the featured event)
```

**Featured-event banner (2026-08-12)**: the Home spotlight is driven by the backend
`events.is_home_featured` flag, not by anything hardcoded. It is derived from the current event
list on every read — never stored — so clearing the flag makes the banner disappear on the
next sync. Full specification, including the Kotlin reference implementation and the
multiple-winner tiebreak: **`FEATURED_EVENT.md`**.

**EventDetailView layout**:
- Full-bleed hero (purple gradient fallback if no image)
- Date card: "Quando" (date + time) and "Dove" (location) in an info card
- "Dove" row is tappable → opens Maps
- Body: plain text description (HTML stripped)
- "Aggiungi al calendario" button → EventKit / Calendar intent
- "Apri evento" link → external browser
- Share button → system share sheet

**Calendar integration**: iOS uses `EventKit`. Android equivalent: `Intent(Intent.ACTION_INSERT, CalendarContract.Events.CONTENT_URI)` with title, begin time, end time, and location extras.

**Maps**: iOS opens `http://maps.apple.com/?q=<encoded_location>`. Android equivalent: `Intent(Intent.ACTION_VIEW, Uri.parse("geo:0,0?q=<encoded_location>"))`.

**Event date parsing**: `dataEvento` is a plain string `"YYYY-MM-DD"`. Time is in `ora` field as `"HH:mm"`. Parse these separately and combine for calendar entry. `rawDate` in the domain model is the combined `Date?` used for `isUpcoming` / `isPast` classification.

---

## 7. Document / PDF Flow

```
DocumentStore.documents
    │
    └── Documenti tab → DocumentiView → list of DocumentListRow
            │
            └── Row tap → DocumentDetailView
                    │
                    └── "Apri PDF" → PDFReaderView (downloads + renders)
```

**Critical**: A document may have a null URL (`url` field missing or null). In this case the document **must still appear** in the list. Show "PDF non disponibile" in place of the open button. Do not filter out URL-less documents.

**PDF loading**:
1. `PDFDownloadService` downloads the remote URL to a local temp file.
2. `PDFKitView` renders the local PDF using `PDFKit.PDFView`.
3. A share button in the toolbar allows sharing the local file.

**Android equivalent**: `DownloadManager` or `OkHttp` to download to cache dir. `PdfRenderer` (API 21+) or a third-party viewer like `AndroidPdfViewer` / `barteksc/AndroidPdfViewer` to render. Share via `FileProvider` + `ACTION_SEND` intent.

---

## 8. Chi siamo (About) Flow

The About screen has four sections:

1. **Intro text**: one paragraph describing the mission.
2. **Mission cards**: three cards (Famiglia, Educazione, Sussidiarietà) with SF Symbol icons and short descriptions.
3. **Support CTA card**: dark card with "Sostieni Ditelo sui Tetti" title, subtitle, and "Sostienici →" button that opens `websiteURL` in the external browser.
4. **Settings list**:
   - Privacy Policy → in-app WebView at `websiteURL/privacy`
   - Termini e condizioni → in-app WebView at `websiteURL/termini`
   - Gestisci notifiche → opens iOS Settings (`UIApplication.openSettingsURLString`)
   - Valuta l'app → `SKStoreReviewController.requestReview` (Android: `ReviewManager` from Play Core)
5. **Developer section**: app version, build number, "Partner tecnologico: Digital Yogin srl", description of Digital Yogin's role.

**Android equivalents**:
- In-app WebView: `WebView` with `WebViewClient`, or `CustomTabsIntent` for Chrome Custom Tabs.
- Open Settings: `Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)`.
- Rate app: Play In-App Review API (`ReviewManager.requestReviewFlow()`).

---

## 9. Push Notification Flow

### 9.1 Permission

Notification permission is requested during onboarding via `NotificationPermissionView`. The OS system dialog is only triggered after the user confirms the custom pre-prompt.

### 9.2 Token registration

After permission is granted, `UIApplication.shared.registerForRemoteNotifications()` is called. The APNs token (hex string) is sent to the `register-push-token` Edge Function:

```
POST /functions/v1/register-push-token
Content-Type: application/json

{
  "deviceToken": "<hex-or-fcm-token>",
  "platform": "android",          // use "android" not "ios"
  "environment": "production",    // no sandbox concept in FCM
  "bundleId": "com.example.app",
  "appVersion": "1.0.0",
  "buildNumber": "1"
}
```

The response is `{"ok": true}` on success. The token is stored locally to avoid re-registering unchanged tokens.

### 9.3 Deep link payload

Push notifications carry a `data` payload with three fields:

```json
{
  "contentType": "article",   // or "event" or "document"
  "id": "<uuid-string>",
  "slug": "<slug-string>"
}
```

On tap, navigate to the corresponding detail screen. Look up by `id` first, fall back to `slug` if not found.

### 9.4 New content detection

After each successful sync, `NewContentDetector` compares the previous and fresh payloads by ID set difference. It detects at most one new article, one new event, and one new document per sync cycle. If the app has no previous cache (first install), no notifications are scheduled (no comparison baseline exists).

---

## 10. Diagnostics Flow

The app includes a hidden diagnostics overlay accessible by tapping the "Sostieni" / Chi siamo hero section five times. It shows:

- Sync endpoint URL
- Last sync counts (articles, events, documents)
- Last 50 log entries from `SyncLogger`

`SyncLogger` is a thread-safe ring buffer (max 50 entries) that also writes to `NSLog` (visible in Console.app / device logs from TestFlight / Firebase Crashlytics console).

Android equivalent: in-app log viewer that reads from `Timber` log tags, or a Logcat bridge for internal builds.

---

## 11. Design Tokens

### Colors

| Token | Hex | Usage |
|-------|-----|-------|
| `brandRed` | `#E8192C` | Primary, CTAs, category chips |
| `brandCream` | `#F2EFE9` | Background of most screens |
| `brandYellow` | `#F5E84A` | Accent, article chips |
| `brandYellowLight` | `#FCEEFA` | Hero italic text |
| `brandBlack` | `#1A1A1A` | Body text, bold titles |
| `brandGray` | `#5E5E5E` | Secondary text, labels |
| `brandGrayLight` | `#A0A0A0` | Tertiary text, dividers |

### Typography

| Role | iOS | Android equivalent |
|------|-----|--------------------|
| Hero title ("Ditelo") | System Black 72pt | Inter Black 72sp |
| Hero subtitle ("sui Tetti.") | Georgia Italic 66pt | Serif italic 66sp |
| Section header | System Bold 19pt | Inter Bold 19sp |
| Body text | System 17pt | Inter Regular 17sp |
| Caption | System 12–13pt | Inter Regular 12–13sp |
| Tagline / category | System Semibold 11pt, kerning | Inter SemiBold 11sp, letter spacing |

### Spacing

| Token | Value |
|-------|-------|
| `DT.padding` | 16 pt |
| `DT.cornerRadius` | 22 pt |
| `DT.smallCorner` | 14 pt |
| `DT.sectionSpacing` | 12 pt |

---

## 12. iOS → Android Technology Mapping

| iOS / SwiftUI | Android / Kotlin equivalent |
|---------------|------------------------------|
| `SwiftUI` | Jetpack Compose |
| `@Observable` store + `@MainActor` | `ViewModel` + `StateFlow` / `MutableStateFlow` |
| `SwiftData` (`@Model`, `ModelContainer`) | Room (Entity, Dao, Database) |
| `URLSession` + `APIClient` | Retrofit + OkHttp |
| `Codable` / `JSONDecoder` | Moshi or Gson (use `@Json(name=)` for field name variants) |
| `PDFKit` / `PDFDocument` | `android.graphics.pdf.PdfRenderer` or `barteksc/AndroidPdfViewer` |
| `WKWebView` | `android.webkit.WebView` or Chrome Custom Tabs |
| `EventKit` | `CalendarContract` via `Intent(ACTION_INSERT)` |
| Apple Maps launcher | `Intent(ACTION_VIEW, "geo:0,0?q=...")` |
| `UNUserNotificationCenter` | Firebase Cloud Messaging (FCM) |
| `SKStoreReviewController` | Play In-App Review API |
| `AsyncImage` | Coil (`AsyncImage` Compose) or Glide |
| `NavigationStack` | Compose Navigation (`NavHost`, `NavController`) |
| `TabView` (tab bar) | `BottomNavigation` or `NavigationBar` in Compose |
| `ShareLink` | `Intent(ACTION_SEND)` |
| `AppStorage` | `DataStore<Preferences>` or `SharedPreferences` |
| `UserDefaults` | `SharedPreferences` |
| `NSLog` | `Timber` / `Log.d` |
| `SyncLogger` ring buffer | Custom `LogBuffer` backed by a fixed-size `ArrayDeque` |
| `@Environment(\.dismiss)` | `navController.popBackStack()` |

---

## 13. File Structure Reference

```
DiteloSuiTetti/
├── App/
│   ├── AppTab.swift              — tab enum (home, articoli, documenti, chiSiamo)
│   └── AppDeepLinkRouter.swift   — observable singleton for push deep links
├── Configuration/
│   └── AppEnvironment.swift      — base URLs, endpoint builders
├── Models/
│   ├── Article.swift             — domain model
│   ├── ArticleDTO.swift          — network DTO
│   ├── Event.swift               — domain model with isUpcoming/isPast
│   ├── EventDTO.swift            — network DTO
│   ├── Document.swift            — domain model
│   ├── DocumentDTO.swift         — network DTO (defensive decoder)
│   └── EditorialSyncResponseDTO.swift — top-level response + Lossy<T> wrapper
├── Mappers/
│   ├── ArticleMapper.swift       — ArticleDTO → Article
│   ├── EventMapper.swift         — EventDTO → Event (date parsing)
│   └── DocumentMapper.swift      — DocumentDTO → Document
├── Stores/
│   ├── ArticleStore.swift        — @Observable ViewModel
│   ├── EventStore.swift          — @Observable ViewModel (upcomingEvents computed)
│   └── DocumentStore.swift       — @Observable ViewModel
├── Persistence/
│   ├── EditorialCacheRepository.swift — SwiftData read/write
│   ├── CachedArticle.swift
│   ├── CachedEvent.swift
│   └── CachedDocument.swift
├── Network/
│   └── APIClient.swift           — URLSession wrapper, retry, logging
├── Services/
│   ├── Sync/EditorialSyncCoordinator.swift — orchestrates network + cache + stores
│   ├── PDF/PDFDownloadService.swift
│   ├── Calendar/EventCalendarService.swift
│   ├── EditorialService.swift    — protocol + live/stub implementations
│   ├── EventService.swift
│   └── DocumentService.swift
├── Notifications/
│   ├── AppNotificationDelegate.swift
│   ├── LocalNotificationManager.swift
│   ├── NewContentDetector.swift
│   ├── NotificationDeepLink.swift
│   └── PushTokenRegistrationService.swift
├── Screens/
│   ├── Home/                     — HomeView, hero components, sections
│   ├── Articles/                 — ArticoliView, ArticleDetailView
│   ├── Events/                   — EventiView, EventDetailView
│   ├── Documents/                — DocumentiView, DocumentDetailView, PDFReaderView
│   ├── About/                    — AboutView
│   ├── Onboarding/               — OnboardingView, NotificationPermissionView
│   ├── Web/                      — WebPageView
│   └── Support/                  — SosteniView (legacy, not in tab bar)
└── Design/
    ├── AppColors.swift
    ├── AppSpacing.swift
    └── AppTypography.swift
```
