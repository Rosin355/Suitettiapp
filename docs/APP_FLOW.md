# App Flow — Ditelo sui Tetti

> Living document for the Android / Jetpack Compose conversion. Describes every screen, its states, and the navigation graph of the live iOS app so it can be rebuilt 1:1 with Compose Navigation. Update this file whenever a screen or edge changes.

---

## 1. Overview

Ditelo sui Tetti is a native SwiftUI civic/editorial app (iOS 26+, iPhone + iPad). The Android target is native Kotlin + Jetpack Compose. The app has three editorial content types — **articles**, **events**, **documents** — synced from a single public Supabase endpoint, cached offline, and presented through a 4-tab interface gated behind a one-time onboarding flow.

State containers (`ArticleStore`, `EventStore`, `DocumentStore`) are `@Observable @MainActor` objects injected via the SwiftUI environment. On Android, mirror them as `ViewModel`s exposing `StateFlow`, with Room + DataStore for cache and Coil for image loading.

### Top-level app gating

The root scene (`DiteloSuiTettiApp`) shows exactly one of three things based on a persisted boolean and a transient flag:

| Condition | Screen shown |
|---|---|
| `hasSeenOnboarding == false` AND notification prompt not yet triggered | **Onboarding** (3 slides) |
| Onboarding finished, OS notification permission still `notDetermined`, prompt flag set | **NotificationPermissionView** (pre-prompt) |
| `hasSeenOnboarding == true` (or `--screenshots` launch arg) | **ContentView** (TabView) |

`hasSeenOnboarding` is the gate (iOS `@AppStorage`; Android = DataStore `Preferences.Key<Boolean>`). Transitions between these three states cross-fade (`.opacity`, ~0.35–0.4 s).

### Launch content loading

When `ContentView` appears it runs `loadContent()`:

1. Read OS notification status; if authorized/provisional/ephemeral, register for remote notifications.
2. **Cache-first**: load cached payload (Room) into the three stores immediately. If no cache, set stores to `loading`.
3. Background **full sync** via `GET /functions/v1/sync-editorial`. On success, replace store contents and overwrite the cache.
4. On sync failure: if cache existed, set an **offline warning** banner (keep showing cached data); if no cache, set **error** state.
5. After detecting new items vs. previous cache, schedule local notifications.
6. Set `router.contentDidLoad = true` so any pending deep link can resolve.

**Featured-event banner across this flow.** The banner is derived from the current event list
on every read, so it follows the same cache-first path with no extra state:

```
launch → restore cached events → banner shows if a cached event is featured
       → live sync → stores replaced wholesale → banner reflects the backend
```

Because step 3 replaces store contents on **every** successful sync (not only when the cache
is rewritten), clearing the flag backend-side removes the banner as soon as that sync lands.
`is_featured` is also part of the cache-invalidation signature, so the persisted cache is
rewritten too and the banner cannot reappear on the next launch. Diagnostics for this are
logged as `[FeaturedEvent] cached=… / remote=… / final=…`.

---

## 2. Text flow diagram

```
                          App launch
                              │
              ┌───────────────┴────────────────┐
              │  hasSeenOnboarding == true ?    │
              └───────────────┬────────────────┘
                     no        │         yes
              ┌───────────────┘                └──────────────┐
              ▼                                                ▼
      ┌───────────────┐                              ┌──────────────────┐
      │  Onboarding   │  swipe / "Avanti"            │   ContentView    │
      │  Slide 0..2   │ ───────────────────────────► │   (TabView)      │
      │ (Salta skips) │      "Inizia →" / Salta       └──────────────────┘
      └───────┬───────┘                                       
              │ onComplete                                    
              ▼                                               
   ┌──────────────────────────┐                              
   │ OS perm == notDetermined? │                              
   └───────┬───────────┬───────┘                              
       no  │           │ yes                                  
           │           ▼                                      
           │   ┌─────────────────────────┐                   
           │   │ NotificationPermission  │                   
           │   │  "Abilita" / "Non ora"  │                   
           │   └───────────┬─────────────┘                   
           └───────────────┘  set hasSeenOnboarding = true   
                              │                               
                              ▼                               
                       ┌──────────────────┐
                       │   ContentView    │  4 tabs, each a NavigationStack
                       └──────────────────┘
        ┌────────────┬───────────────┬───────────────┬───────────────┐
        ▼            ▼               ▼               ▼
     Home         Articoli        Documenti       Chi siamo
   (.home)       (.articoli)      (.documenti)    (.chiSiamo)
        │            │               │               │
        │            ▼               ▼               ├─ Privacy Policy (push)
        │      Article detail   Document detail      ├─ Social links (sheet)
        │            │               │               ├─ Rate app (sheet)
        │            │               ▼               └─ Donation sheet (sheet)
        │            │           PDF reader               └─ (IBAN copy)
        │            │ (Documenti allegati ─► PDF reader)
        │            │
        ├─ "In evidenza" article ─► Article detail
        ├─ "Prossimi eventi" ─► Event detail ─► PDF reader (Documenti dell'evento)
        └─ "Tutti →" events ─► EventiView (events list) ─► Event detail

  Deep link (notification tap / suitetti.org/{articoli|eventi|documenti}/{slug}):
     article  → selectedTab = .articoli, push Article detail
     event    → selectedTab = .home,     push Event detail
     document → selectedTab = .documenti, push Document detail
```

---

## 3. Screen catalogue

### 3.1 Onboarding (`OnboardingView`)

**Purpose**: First-run brand introduction. Three full-screen swipeable slides (horizontal pager, no system index dots — a custom capsule dot indicator is drawn).

**Content per slide**:

| # | Theme bg | Content |
|---|---|---|
| 0 | Cream | Eyebrow "CHI SIAMO", title "La nostra missione.", 3 pillar cards: Famiglia (heart, red), Educazione (book, green `#2A7A4B`), Sussidiarietà (network, indigo `#5B52D0`). Each card = icon tile + title + detail. |
| 1 | Brand red | App-icon logo mark, "Ditelo" (black) + "sui Tetti." (Georgia italic, yellow), tagline "La voce civica per la vita, la famiglia e l'educazione." |
| 2 | Dark `#1A1A1A` | Badge "3° FESTIVAL", title "SUI TETTI / FESTIVAL 2026", italic gold subtitle "Insieme per il bene comune.", body paragraph, closing "Ti aspettiamo. ♡" |

Each slide has an animated bokeh-circle background (`OnboardingBokehBackground`, cream/red/dark themes). Slide content fades + slides up on appear (guard with Reduce Motion).

**Controls**:
- "Salta" (Skip) top-right, hidden on the last slide.
- Capsule dot indicator (active dot elongated), tappable to jump.
- Bottom CTA pill: "Avanti" on slides 0–1, "Inizia →" on slide 2. On slide 1 the pill is frosted glass; otherwise solid red. Haptic on tap.

**States**: static content only — no loading/error/empty.

**Navigation edges**:
- "Salta" → `onComplete()`.
- "Avanti" → next slide; "Inizia →" → `onComplete()`.
- `onComplete` checks OS notification status: if already answered (authorized/provisional/denied/ephemeral) → set `hasSeenOnboarding = true` (go to ContentView); else → show NotificationPermissionView.

---

### 3.2 Notification permission pre-prompt (`NotificationPermissionView`)

**Purpose**: Soft pre-prompt explaining why notifications help, shown once between onboarding and the main app (only when OS permission is still undetermined).

**Content**: Cream→white gradient, bell badge icon, title "Rimani aggiornato", subtitle, and 3 feature cards: Nuovi articoli (doc, red), Eventi (calendar, green), Documenti (folder, indigo). Two bottom CTAs.

**States**: static only.

**Navigation edges**:
- "Abilita notifiche" → request OS authorization; if granted, register for remote notifications; then set `hasSeenOnboarding = true` → ContentView.
- "Non ora" → set `hasSeenOnboarding = true` → ContentView (no permission request).

> Android: this is the soft pre-prompt before `POST_NOTIFICATIONS` (Android 13+) / `NotificationManagerCompat.areNotificationsEnabled()`.

---

### 3.3 ContentView — main TabView (`ContentView`)

**Purpose**: Root container after gating. SwiftUI `TabView` with 4 tabs, each wrapping its own `NavigationStack`. Tint = brand red. A floating "Liquid Glass" tab bar.

| Tab value | Label | SF Symbol | Root screen | Nav title |
|---|---|---|---|---|
| `.home` | Home | `house.fill` | `HomeView` | (hidden — custom top bar) |
| `.articoli` | Articoli | `doc.text.fill` | `ArticoliView` | "Articoli" |
| `.documenti` | Documenti | `folder.fill` | `DocumentiView` | "Documenti" |
| `.chiSiamo` | Chi siamo | `info.circle.fill` | `AboutView` | "Chi siamo" |

Each tab declares an `isPresented`-style `navigationDestination` so a resolved deep link can push the relevant detail onto that tab's stack.

**Deep link resolution** (`resolveDeepLink`), triggered by a notification tap or a `suitetti.org/{articoli|eventi|documenti}/{slug}` link, after `contentDidLoad`:
- `.article` → match by id then slug → select `.articoli` tab → push `ArticleDetailView`.
- `.event` → match by id then slug → select `.home` tab → push `EventDetailView`.
- `.document` → match by id then slug → select `.documenti` tab → push `DocumentDetailView`.

> Compose: a single `NavHost` with a bottom `NavigationBar`. Each tab is a nested graph; deep links handled via `navController.handleDeepLink` / `deepLinks { uriPattern = "https://suitetti.org/articoli/{slug}" }`.

---

### 3.4 Home (`HomeView`) — tab `.home`

**Purpose**: Editorial landing page. Vertical `ScrollView`; navigation bar hidden in favour of a custom floating top bar (`HomeTopBar`) that fades in after scrolling ~220 pt past the hero. Background = brand cream.

**Sections (top to bottom)**:
1. **Hero** (`HomeHeroSection`) — animated brand lockup ("Ditelo sui Tetti"), full width.
2. **Ticker** (`HeroTickerView`) — full-width scrolling ticker.
3. **Stats strip** (`HeroStatsView`, part of `HomeHeroSection`, on a transparent dark gradient over the mesh — no blur): three **evergreen** static stats — `100+ Associazioni`, `312 Comitati`, `Italia · Rete civica`. (The separate `HomeStatsStrip` and its date-bound `16 giu · 3° Festival` stat were removed 2026-07-02 so the hero never goes stale.)
4. **In evidenza** (`HomeFeaturedArticlesSection`) — section header "In evidenza" with "Vedi tutti" action (switches to `.articoli` tab). Shows the **first 6** articles. iPhone = vertical card list (`ArticleListRow`); iPad = 2-column grid. Each card → `ArticleDetailView` via `NavigationLink` with `.navigationTransition(.zoom)`.
5. **Evento in evidenza** (`HomeFeaturedEventSection` → `HomeFeaturedEventCard`) — the single editorial spotlight, driven entirely by the backend `is_featured` flag. Renders **only** when `EventStore.featuredEvent != nil`; otherwise the section emits nothing at all (no placeholder, no reserved space). Tapping pushes the native `EventDetailView`. Replaced the hardcoded Festival CTA on 2026-08-12.
6. **Prossimi eventi** (`HomeEventsSection`) — header "Prossimi eventi" with "Tutti →" → `EventiView`. Shows first 3 upcoming events as `EventRow`s; each → `EventDetailView`. Empty copy: "Nessun evento in programma." The promoted event is filtered out of this preview so it never appears twice on one screen; if it was the *only* upcoming event, the whole section stands down rather than contradicting the banner with "Nessun evento in programma". `EventiView` still lists it.
7. **Quote card**.
8. Bottom clearance spacer (~130 pt) so content clears the floating tab bar.

On iPad, editorial content is clamped to `readableMaxWidth` (820) and centred; hero + ticker stay full width.

**States**: Home reads the shared stores. Sections render only when their store has data; events section shows its own empty copy. There is no full-screen loading/error here — the stores' loading/error/offline surfaces primarily on Articoli/Documenti. Treat Home sections as "show when populated".

**Navigation edges**: "Vedi tutti" → Articoli tab; featured article → Article detail; "Tutti →" → Events list; event row → Event detail; **featured-event banner → Event detail (native, in-app — never the website)**.

---

### 3.5 Articoli (`ArticoliView`) — tab `.articoli`

**Purpose**: Full article browser with category filter. Adaptive: iPhone single-column; iPad two-column split.

**Content**:
- **Filter bar** (`ArticlesFilterBar`): horizontal category chips, first chip "Tutto". Placed **outside** the vertical `ScrollView` (so the horizontal scroll gesture is not nested — important to replicate on Android to avoid nested-scroll tap interception). Categories come from `store.categories`.
- **List** (`ArticlesListSection`): when category == "Tutto", the **first** article renders as a large **featured hero card** (`ArticlesFeaturedCard`) and the remaining articles render as `ArticleListRow`s below (no duplication). When a filter is active, no featured card — just the filtered list.
- Optional **offline badge** ("wifi.slash" + message) above the filter bar when `offlineMessage` is set.
- Pull-to-refresh triggers `store.refresh()` + success haptic.

**iPad split layout** (`horizontalSizeClass == .regular`): `GeometryReader` + `HStack`. Left pane = filter bar + list, width `max(280, min(400, width * 0.40))`. Right pane = `ArticleDetailView(isEmbedded: true)` or a placeholder ("Seleziona un articolo"). Selection uses an `onSelect` closure (not a push); default selection = first filtered article; zoom/move transition unless Reduce Motion.

**iPhone layout**: list rows are `NavigationLink`s pushing `ArticleDetailView` with `.navigationTransition(.zoom)`.

**States** (priority order):
1. **Loading**: `isLoading && articles.isEmpty` → `SkeletonLoadingList`.
2. **Error**: `errorMessage != nil && articles.isEmpty` → `EmptyStateView` (icon `wifi.slash`, title "Errore di caricamento", subtitle = message, "Riprova" → `store.load()`).
3. **Empty**: `articles.isEmpty` → `EmptyStateView` (icon `doc.text`, "Nessun articolo", "Non sono presenti articoli al momento.").
4. **Content**: iPad split or iPhone list.

**Navigation edges**: any article → Article detail. Category chip → filters in place. If the selected category disappears from the category list, reset to "Tutto".

---

### 3.6 Eventi (`EventiView`) — pushed from Home "Tutti →"

**Purpose**: Full events list. Reached by pushing onto the Home stack (nav title "Eventi"). Rows → `EventDetailView`. Same loading/error/empty conventions as the other list screens.

> Not a tab — it lives inside the Home `NavigationStack`. On Android it is a route under the Home graph, e.g. `home/events`.

---

### 3.7 Article detail (`ArticleDetailView`)

**Purpose**: Read a single article. Vertical `ScrollView`, cream background, nav bar hidden; floating back + share buttons overlaid at top. Content column clamped to `readableMaxWidth`.

**Content (top to bottom)**:
1. **Hero image** (`DetailHeroImage`) — remote image (height 340; 240 when embedded on iPad), brand-logo fallback if URL nil or load fails.
2. **Title card** (`DetailTitleCard`) — category chip (tinted by `categoryColor`), title, metadata row (calendar + `fullDate` · clock + read time).
3. **Excerpt** (italic, only if it differs from the body prefix).
4. **Body** — `contenuto` HTML stripped to plain text. If body empty, fall back to excerpt; if both empty → "Contenuto non disponibile." placeholder.
5. **Documenti allegati** — only when `relatedDocuments` is non-empty: separator + uppercase heading "DOCUMENTI ALLEGATI" + a list of `LinkedDocumentCard`s (premium PDF cards).

**States**: content-only; the empty-body placeholder is the only "empty" surface. No loading/error (article already in memory). Attachment cards open the PDF reader.

**Navigation edges**:
- Back button → pop (hidden when embedded in iPad split).
- Share button → `ShareLink` of `https://suitetti.org/articoli/{slug}`.
- `LinkedDocumentCard` → opens its PDF (see §3.13).

---

### 3.8 Event detail (`EventDetailView`)

**Purpose**: Show one event. Same layout shell as Article detail (scroll, cream bg, floating back/share, readable-width column, indigo hero fallback colours).

**Content**:
1. **Hero image** (`DetailHeroImage`, height 340, indigo gradient fallback).
2. **Title card** — label = `type` (or "Evento"), indigo accent, title.
3. **Info cards** (`EventInfoCard`, in a single rounded card):
   - **Quando** — calendar icon, `fullDate`, plus "ore {time}" secondary line when `time` is present.
   - **Dove** — map-pin icon, `location`; tapping opens Apple Maps (`MapsLauncher`). Shown only when `location` is non-empty.
4. **Description** — `descrizione` HTML stripped to plain text (only if non-empty, preceded by a separator).
5. **Action buttons**:
   - "Aggiungi al calendario" (prominent red) → EventKit save (`EventCalendarService`). Success alert "Evento salvato"; error alert "Errore calendario" with an "Impostazioni" button when access is denied.
   - "Apri evento" (bordered) → opens `link` in browser, only when `link` is present.
6. **Documenti dell'evento** — same pattern as articles: heading "DOCUMENTI DELL'EVENTO" + `LinkedDocumentCard`s, only when `relatedDocuments` is non-empty.

**States**: content-only; calendar save has success/error alerts. Map tap and external link are conditional on data presence.

**Navigation edges**: back (pop), share (`ShareLink` of formatted text), Maps deep link, external event link, attachment → PDF reader.

> Android: add-to-calendar = `Intent(Intent.ACTION_INSERT, CalendarContract.Events.CONTENT_URI)` or the Calendar Provider; map tap = `geo:` Intent.

---

### 3.9 Documenti (`DocumentiView`) — tab `.documenti`

**Purpose**: List of all documents (single rounded card containing `DocumentListRow`s). Each row → `DocumentDetailView` via `NavigationLink` (pressable card style). Pull-to-refresh + success haptic. On iPad the list is clamped to `readableMaxWidth` and centred. Optional offline badge at top.

**States** (priority order):
1. **Loading**: `isLoading` → `SkeletonLoadingList`.
2. **Error**: `errorMessage != nil` → `EmptyStateView` (`wifi.slash`, "Connessione non disponibile", "Riprova" → `store.refresh()`).
3. **Empty**: `documents.isEmpty` → `EmptyStateView` (`doc.on.doc`, "Nessun documento", "Non sono presenti documenti al momento.").
4. **Content**: document list.

**Navigation edges**: any row → Document detail.

---

### 3.10 Document detail (`DocumentDetailView`)

**Purpose**: Document metadata + open actions. Scroll, cream bg, inline nav title "Documento", readable-width column.

**Content**:
1. **Header** — type chip (red) + category chip (gray, when present) + bold title.
2. **Metadata card** — rows: "Caricato il" (`uploadedAt`), "Categoria", "Tipo" (placeholders "—" when empty).
3. **Description** — `descrizione` stripped to plain text (when present).
4. **Actions** (when `url` present):
   - "Leggi PDF" (prominent red) → `NavigationLink` to `PDFReaderView(remoteURL:title:)`.
   - "Apri esternamente" (bordered) → open URL in browser.
   - Share button → `ShareLink` of the URL.
   - When `url` is nil → "PDF non disponibile" placeholder (icon `doc.slash`).

**States**: content-only; the no-URL placeholder is the empty surface.

> Data caveat for Android: 7 of 25 documents currently carry legacy `www.suitetti.org` URLs that 404 / return HTML. Prefer a direct `.pdf` URL among candidate fields; the reader validates the downloaded file is a real PDF and shows an error otherwise.

---

### 3.11 PDF reader (`PDFReaderView`)

**Purpose**: In-app PDF viewing (PDFKit `PDFKitView`). Inline nav title = document/attachment title; cream bg; toolbar share button (shares the downloaded local file). Used by both Document detail ("Leggi PDF") and attachment cards.

**Download/validation** (`PDFDownloadService`): download to tmp, validate MIME/extension, cache locally; logged via `[DocumentURL]` / `[DocumentPDF]` diagnostics.

**States**:
1. **Loading**: spinner + "Caricamento PDF…".
2. **Error**: warning icon + message (e.g. "Il file scaricato non è un PDF valido." or the error description) + "Riprova" button.
3. **Content**: rendered `PDFKitView`.

> Android equivalent: bundled `PdfRenderer` for downloaded files, or WebView / Chrome Custom Tabs fallback. Always use the resolved backend URL.

---

### 3.12 Chi siamo / About (`AboutView`) — tab `.chiSiamo`

**Purpose**: About + settings hub. Scroll, cream bg, large nav title "Chi siamo". Readable-width clamp on iPad.

**Content (sections)**:
1. **Hero intro** — mission paragraph.
2. **I nostri valori** — 3 pillar cards (Famiglia, Educazione, Sussidiarietà).
3. **Support CTA** — dark gradient card "Sostieni Ditelo sui Tetti" → opens donation sheet.
4. **Impostazioni** — rows:
   - "Privacy Policy" → `NavigationLink` to `PrivacyPolicyView` (push).
   - "Seguici sui social" → social links sheet.
   - "Gestisci notifiche" → opens OS Settings (`UIApplication.openSettingsURLString`).
   - "Valuta l'app" → rate-app sheet.
   - (Terms & Conditions row is present in code but commented out / hidden.)
5. **Sviluppo e tecnologia** — Digital Yogin srl card, tech-stack chips (Swift, SwiftUI, SwiftData, Supabase, PDFKit, WebKit, APNs), "Visita Digital Yogin" link, and a version/build footer ("Versione X (Y)").

**States**: static.

**Navigation edges**: Privacy (push), and 3 modal sheets (donation, social, rate). "Gestisci notifiche" and "Visita Digital Yogin" leave the app.

> Note: the donation sheet and the 5-tap diagnostics are reached from two different places. The donation sheet (IBAN copy) is presented from About's "Sostieni" CTA. The 5-tap hidden diagnostics live on `SosteniView` (see §3.16), a support screen that contains the notification-status row and the hidden gesture.

---

### 3.13 LinkedDocumentCard (attachment open behaviour)

`LinkedDocumentCard` renders an attachment (`RelatedDocument` = id, title, type, description, url; no date/size). VoiceOver label: "Apri documento PDF, {title}". Tapping opens the attachment URL in the PDF reader (same flow as §3.11). Used inside Article detail ("Documenti allegati") and Event detail ("Documenti dell'evento").

---

### 3.14 Donation / Support sheet (`SupportDonationSheet`)

**Purpose**: Bank-transfer donation details (modal sheet, large detent, drag indicator). Presented from About.

**Content**: intro paragraph; bank-details card with rows — Intestatario, Indirizzo, IBAN (`IT43C0306909606100000186533`, monospaced), BIC (`BCTTTTMM`, monospaced), Banca (Banca Intesa Sanpaolo); all selectable. Two copy buttons:
- "Copia IBAN" → copies IBAN to clipboard, flips to "Copiato ✓" for 2 s, success haptic.
- "Copia coordinate" → copies all bank details, same feedback.

**States**: static. **Edges**: "Chiudi" dismisses.

> Android: `ClipboardManager.setPrimaryClip` for copy; ModalBottomSheet for presentation.

---

### 3.15 Privacy Policy (`PrivacyPolicyView`)

**Purpose**: Native in-app privacy policy text screen, pushed from the About → Impostazioni "Privacy Policy" row. Static content.

> Android: a plain scrollable composable route `about/privacy`.

---

### 3.16 Social links sheet (`SocialLinksSheet`) & Sostieni / diagnostics (`SosteniView`)

**SocialLinksSheet** — modal sheet (medium detent). Rows: Facebook (`facebook.com/DiteloSuiTetti`), X (`x.com/DiteloSuiTetti`), YouTube (`youtube.com/@DiteloSuiTetti`); each opens externally. Footer note. "Chiudi" dismisses.

**SosteniView** — a support screen (hero + 4 "ways to help" action cards + a notification-status row showing Abilitate / Non abilitate / Non ancora richieste, with an "Apri" button to OS settings when denied). It carries the **5-tap hidden gesture** (`onTapGesture(count: 5)`) that presents `SyncDiagnosticsView` as a sheet.

---

### 3.17 Sync diagnostics (`SyncDiagnosticsView`) — hidden

**Purpose**: Hidden developer panel, opened by tapping the support screen 5 times. Modal `NavigationStack` + `List`:
- **Endpoint** — the sync URL (monospaced, selectable).
- **Ultima sincronizzazione** — last article / event / document counts.
- **Log** — reversed `SyncLogger` entries (monospaced, selectable).
- Toolbar: "Chiudi" (dismiss), "Cancella" (clear log).

> Android: gate behind a 5-tap detector on the support screen; back the data with a small in-memory `SyncLogger` singleton.

---

## 4. Compose NavHost route sketch

```kotlin
// Top-level gate decides the start destination.
@Composable
fun RootApp(prefs: AppPreferences /* DataStore */) {
    val hasSeenOnboarding by prefs.hasSeenOnboarding.collectAsState(initial = null)
    when (hasSeenOnboarding) {
        null  -> SplashPlaceholder()                 // while DataStore loads
        false -> OnboardingFlow(onFinished = { /* may route to perm prompt */ })
        true  -> MainScaffold()
    }
}

// Onboarding + permission pre-prompt live in their own graph (or simple state).
sealed interface Gate {
    data object Onboarding : Gate          // 3-page HorizontalPager
    data object NotifyPrompt : Gate        // soft pre-prompt
    data object Main : Gate
}

@Composable
fun MainScaffold() {
    val nav = rememberNavController()
    Scaffold(
        bottomBar = { AppBottomBar(nav) }  // floating, translucent (Liquid Glass analogue)
    ) { padding ->
        NavHost(
            navController = nav,
            startDestination = "home",     // graph route
            modifier = Modifier.padding(padding)
        ) {
            // ---- HOME GRAPH (.home) ----
            navigation(startDestination = "home/feed", route = "home") {
                composable("home/feed") { HomeScreen(nav) }              // hero, stats, In evidenza, Prossimi eventi
                composable("home/events") { EventsListScreen(nav) }      // "Tutti →" (EventiView)
                composable(
                    "event/{id}",
                    deepLinks = listOf(navDeepLink { uriPattern = "https://suitetti.org/eventi/{slug}" })
                ) { EventDetailScreen(nav) }                              // -> pdf/{url}
            }

            // ---- ARTICOLI GRAPH (.articoli) ----
            navigation(startDestination = "articoli/list", route = "articoli") {
                composable("articoli/list") { ArticlesScreen(nav) }      // filter bar + featured hero + list; iPad split
                composable(
                    "article/{id}",
                    deepLinks = listOf(navDeepLink { uriPattern = "https://suitetti.org/articoli/{slug}" })
                ) { ArticleDetailScreen(nav) }                           // body + "Documenti allegati" -> pdf/{url}
            }

            // ---- DOCUMENTI GRAPH (.documenti) ----
            navigation(startDestination = "documenti/list", route = "documenti") {
                composable("documenti/list") { DocumentsScreen(nav) }
                composable(
                    "document/{id}",
                    deepLinks = listOf(navDeepLink { uriPattern = "https://suitetti.org/documenti/{slug}" })
                ) { DocumentDetailScreen(nav) }                          // "Leggi PDF" -> pdf/{url}
            }

            // ---- CHI SIAMO GRAPH (.chiSiamo) ----
            navigation(startDestination = "about/home", route = "chiSiamo") {
                composable("about/home") { AboutScreen(nav) }
                composable("about/privacy") { PrivacyPolicyScreen() }    // pushed
                composable("about/support") { SupportScreen(nav) }       // SosteniView: ways-to-help + notif status + 5-tap gesture
            }

            // ---- SHARED LEAF: PDF reader (URL-encode the resolved url) ----
            composable("pdf/{encodedUrl}") { PdfReaderScreen() }         // PdfRenderer / WebView / Custom Tab
        }
    }
}

// Modal surfaces are ModalBottomSheet state, not NavHost routes:
//   SupportDonationSheet (IBAN copy)  — large sheet, from About support CTA
//   SocialLinksSheet                  — medium sheet
//   RateAppSheet                      — sheet
//   SyncDiagnosticsView               — sheet, gated behind 5-tap on SupportScreen
```

### Route ↔ iOS screen map

| Compose route | iOS screen | Notes |
|---|---|---|
| `OnboardingFlow` | `OnboardingView` | 3-page pager, Salta/Avanti/Inizia |
| `NotifyPrompt` | `NotificationPermissionView` | soft pre-prompt; only if OS perm undetermined |
| `home/feed` | `HomeView` | hero, stats, In evidenza (first 6), Prossimi eventi (first 3) |
| `home/events` | `EventiView` | pushed from "Tutti →" |
| `event/{id}` | `EventDetailView` | Quando/Dove, add-to-calendar, Documenti dell'evento |
| `articoli/list` | `ArticoliView` | filter bar + featured hero + list; iPad split |
| `article/{id}` | `ArticleDetailView` | body + Documenti allegati |
| `documenti/list` | `DocumentiView` | document rows |
| `document/{id}` | `DocumentDetailView` | metadata + Leggi PDF / Apri esternamente / Share |
| `pdf/{encodedUrl}` | `PDFReaderView` | shared leaf for documents + attachments |
| `about/home` | `AboutView` | intro, valori, support CTA, settings, developer |
| `about/privacy` | `PrivacyPolicyView` | pushed |
| `about/support` | `SosteniView` | ways-to-help + notif status + 5-tap diagnostics |
| sheet | `SupportDonationSheet` | IBAN copy |
| sheet | `SocialLinksSheet` | FB / X / YouTube |
| sheet | `RateAppSheet` | store rating |
| sheet (5-tap) | `SyncDiagnosticsView` | endpoint, counts, log |

---

## 5. Cross-cutting state conventions (for Compose)

Every list-bearing store (articles, documents, and analogously events) exposes the same four UI states. Mirror them exactly:

| State | Trigger | UI |
|---|---|---|
| Loading | `isLoading && items.isEmpty` | skeleton list |
| Error | `errorMessage != null && items.isEmpty` (no cache) | full-screen empty-state with "Riprova" |
| Empty | `items.isEmpty` (loaded, no error) | full-screen empty-state, no retry |
| Content | items present | list / grid |
| Offline (overlay) | sync failed but cache existed | inline "wifi.slash" badge above content; data still shown |

Detail screens (article/event/document) are content-only because the entity is already in memory; their only "empty" surfaces are the body/PDF-unavailable placeholders. The PDF reader has its own loading/error/content states.

**Images**: two-tier cache (memory + disk). On nil URL or load failure, fall back to the official Ditelo sui Tetti brand logo asset (cream background, `scaledToFit`, 1:1 in thumbnails) — never a random gradient for editorial content. Android = Coil with disk cache + a fallback painter pointing at the same brand-logo asset.

**Design tokens**: cornerRadius 22, smallCorner 14, padding 16, sectionSpacing 12, readableMaxWidth 820, topBarContentOffset 62. Colors: brandCream `#F5EFE6`, brandRed `~#C0141E`, brandBlack, brandGray/brandGrayLight (metadata), brandSep (separators). Glass surfaces = translucent white at ~0.82 opacity + ultraThin/thin material + subtle shadows + rounded floating controls.

**Accessibility**: combine/ignore row children into single VoiceOver elements; min 44×44 pt (48 dp Android) tap targets; Dynamic Type; Reduce Motion guards on the appear/zoom animations; brandGray metadata for sufficient contrast.

---

## Addendum — flow changes (2026-06-09)

- **Home**: the black festival CTA (`HomeReferendumCTA`, "Scopri l'evento del 16 giugno") is **disabled in v1.0** — it navigated nowhere and duplicated "Prossimi eventi". The component remains as a future promotional-banner slot but is not rendered. "Prossimi eventi" is unchanged.
- **Share** (article/event/document detail): the share button now produces an inviting message containing the **canonical** `https://www.suitetti.org/{articoli|eventi|documenti}/{slug}` URL + the store listing — not a bare/legacy URL. PDF "Leggi PDF" / "Apri esternamente" still use the real PDF URL.
- **About → "Supporto tecnico"** (new card, before the developer section): taps open a `mailto:` to **info@digitalyogin.com** with a version/build-stamped subject; a fallback alert appears if no mail client is available.

## Addendum — flow changes (2026-07-02)

- **Home hero stats** are now evergreen (`Italia · Rete civica` replaces `16 giu · 3° Festival`); the dead `HomeStatsStrip` was deleted. `HeroStatsView` is the live strip inside `HomeHeroSection`.
- **Home Festival spotlight**: a new `HomePromoCard` ("SPECIALE · 3° Festival — rivivi video e materiali") replaces the old, disabled `HomeReferendumCTA`. Tapping opens `AppEnvironment.festivalURL` in the **external browser** (SwiftUI `openURL`) — the festival page is rich web content that reads best full-screen in Safari. (An earlier iteration used an in-app `WebSheet`; those WebView components remain in the codebase but are no longer wired to this card.)
  > Android: open externally with `Intent(Intent.ACTION_VIEW, uri)` (default browser). The festival hub URL is a website destination, not part of the sync payload.
- **Onboarding slide 2** is evergreen: badge `IL FESTIVAL`, title `SUI TETTI / FESTIVAL`, closing "Ci vediamo sui tetti. ♡" (was `3° FESTIVAL` / `FESTIVAL 2026` / "Ti aspettiamo. ♡").
- A Festival remains a normal **event** (`tipo: "Festival"`) with the full native `EventDetailView`; a dedicated native `FestivalDetailView` (video + related articles, "Option B") is backend-gated — see `API_CONTRACT.md` → "Proposed: Festival / Project content".

---

## Addendum — dynamic featured event (2026-08-12)

- **Home Festival spotlight removed.** The hardcoded `HomePromoCard` ("SPECIALE · 3° Festival")
  is no longer rendered. It could only ever point at one fixed event and had to be edited in
  code whenever the campaign changed. `HomePromoCard` stays in the codebase as a reusable
  component for future campaigns.
- **Replaced by `HomeFeaturedEventCard`**, driven by the backend `events.is_featured` flag.
  An editor toggles "in evidenza" in the CMS; the banner appears on the next sync. Clearing it
  removes the banner. No app release is involved in either direction.
- The banner opens the **native** `EventDetailView` — not the website. This is a change of kind
  from the old card, which left the app for the festival web page.
- Placement: after "In evidenza", immediately before "Prossimi eventi".
- Nothing about the banner is persisted separately. It is recomputed from `EventStore.events`,
  which is what makes disappearance automatic.

> Android: mirror exactly. Derive the banner from the same `is_featured` field, render nothing
> when no event is flagged, and navigate to the existing event-detail route. Do not implement
> local business logic (date windows, "latest festival", hardcoded slugs) to decide what to
> promote — the backend is the only source of truth.
