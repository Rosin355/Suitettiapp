# ROADMAP — Ditelo sui Tetti iOS

Tasks are tracked here as the single source of truth across AI sessions.

---

## Completed — v1.0 Core

- [x] **Home** — animated MeshGradient hero, stats strip, featured articles, upcoming events, quote section
- [x] **Articoli** — category filter bar (outside scroll view — no tap interception), article list, article detail with body text, floating glass controls; zoom transitions on iPhone; 2-column split panel on iPad
- [x] **Documenti** — document list, document detail, native PDF reader with download, share, loading/error/retry
- [x] **Chi siamo / AboutView** — intro, mission cards, support CTA (IBAN copy sheet), Privacy Policy screen, rate app sheet, social links sheet, Digital Yogin developer section
- [x] **SosteniView** — support screen, notification settings row, 5-tap hidden diagnostics entry
- [x] **Event detail** — hero, event info cards, "Aggiungi al calendario" CTA, Apple Maps tap
- [x] **EventiView** — upcoming/past/all filter, empty state with smart fallback
- [x] **iPad adaptive layout** — readable-width content constraint (820pt), split-panel ArticoliView, 2-column home grid, adaptive hero typography
- [x] **Accessibility pass** — VoiceOver `.accessibilityElement(children: .combine)` + labels on list rows; 44×44pt tap targets; `.brandGray` for metadata contrast; Reduce Motion guards on all animations; Stage Manager adaptive panel widths
- [x] **SwiftData offline cache** — `CachedArticle`, `CachedEvent`, `CachedDocument`; cache-first launch; non-blocking offline banner; `EditorialCacheRepository`
- [x] **Unified sync coordinator** — single `sync-editorial` request at launch; `EditorialSyncCoordinator`; `?since=` delta parameter available
- [x] **Resilient/lossy decoding** — `Lossy<T>` wrapper (internal); articles, events, documents all decoded per-item; one bad item never empties section; index-based per-item error logs; `Date.distantPast` fallback; `AttachmentDTO` extended title fallbacks (`name`, `attachmentName`, `filename`)
- [x] **SyncLogger + SyncDiagnosticsView** — 50-entry ring buffer; Console.app visible in all builds; 5-tap access from SosteniView
- [x] **APNs push token registration** — device token registered on first launch; `PushTokenRegistrationService` deduplicates; `register-push-token` Edge Function deployed
- [x] **Privacy Manifest** — `PrivacyInfo.xcprivacy` created (UserDefaults, Device ID/AppFunctionality); **must be added to Xcode target manually**
- [x] **Screenshot Capture Mode** — `--screenshots` launch argument; `AppStorePreviewData` injects fixtures; bypasses network + onboarding
- [x] **App icon** — 1024×1024 marketing icon present
- [x] **Onboarding** — 3-slide onboarding with animated bokeh backgrounds; `@AppStorage("hasSeenOnboarding")` gate
- [x] **URLCache hardening** — `URLCache.shared` enlarged to 50 MB memory / 200 MB disk to prevent image eviction between tabs
- [x] **Persistent image cache** — `ImageCache` (NSCache 100 items/50MB + FileManager disk) replaces `AsyncImage` in `RemoteImageView`; load order: memory → disk → network; `[ImageCache]` + `[ArticleListRow]` NSLog diagnostics; consistent thumbnail loading at any frame size
- [x] **Dark Mode navigation title fix** — all cream-background screens use `.toolbarBackground(.brandCream)` + `.toolbarColorScheme(.light)` so large titles render dark in both modes (`ArticoliView`, `DocumentiView`, `EventiView`, `AboutView`, `SosteniView`)
- [x] **Article/Event PDF attachment support (iOS)** — full pipeline: `AttachmentDTO` → `RelatedDocument` → `CachedArticle/CachedEvent` (SwiftData JSON column) → `LinkedDocumentCard` in detail views
- [x] **Latest-content ordering (RC, 2026-06-09)** — `EditorialSort` single source of truth; `Article`/`Document` carry `publishedAt`; `ArticleStore`/`DocumentStore` sort newest-first on every path (live, cache restore, pull-to-refresh); undated items sort last; cache schema bumped to v2 with one-time stale purge; `[SyncDiag]` first-5 diagnostics. Verified live: articles & documents descending; null-`ora` event recovered (62 → 63)
- [x] **Event decode hardening (RC, 2026-06-09)** — `EventDTO`: only `id`/`titolo` are hard-required; `ora`/`tipo`/`luogo`/`descrizione`/`dataEvento`/`slug`/`syncVersion` tolerate null/missing so a malformed event never drops
- [x] **Document URL resilience (RC, 2026-06-09)** — `DocumentDTO` URL decode tries `url`/`file_url`/`document_url`/`public_url`/`link`; docs without a URL render disabled, valid PDFs stay tappable
- [x] **Backend: allegati migration deployed** — `public.allegati` table with polymorphic `parent_type + parent_id`, soft delete, `is_mobile_visible`, delta-sync trigger
- [x] **Backend: sync-editorial attachments deployed** — `attachments: []` on every article and event; never null
- [x] **Backend: send-apns-push deployed** — production APNs push with `content_type`, `content_id`, `url`
- [x] **Backend: notify-content-published deployed** — triggers on new content publish; constructs `https://www.suitetti.org/{articoli|eventi|documenti}/{slug}` URLs

---

## PHASE 10 — Article cache reconciliation (2026-06-17)

- [x] **Root cause**: `ArticleDTO` decoded `categoria`/`estratto`/`contenuto`/`syncVersion` as non-optional → any article with a null field (e.g. "Grazie!!" with `estratto: null`) was dropped by the per-item `Lossy` decode and never shown.
- [x] **Fix**: `ArticleDTO` now resilient — only `id`+`titolo` required, everything else tolerates null/missing. No article dropped by empty field or category.
- [x] **Verification logs**: `[SyncPayload]` / `[ArticleMapper]` / `[ArticleStore]` count + `contains Grazie` + first-10.
- [x] **Recovery net**: store rebuilt from payload + cache rebuilt if any payload article id is missing from the store (`[ArticleStore] recovery mismatch`).
- [x] Builds on PHASE-9 cache work (`.reloadIgnoringLocalCacheData` fetch + full `clearAndReplace` reconcile) so the store always mirrors the sync payload.

---

## PHASE 9 — RC resubmission fixes (2026-06-09)

- [x] **Canonical share URLs** — all share buttons (article/event/document) and "Copia link sito" use `https://www.suitetti.org/{articoli|eventi|documenti}/{slug}` via `AppEnvironment` builders + the new `ShareMessage` util. Legacy `comitaticivici.it` removed from every share path. Share text now invites the reader and links the App Store listing. `[Share] … url=` logs added.
- [x] **Home festival CTA disabled** — `HomeReferendumCTA` render commented out (kept as a future promotional-banner slot); event already shown in "Prossimi eventi"; no layout gap.
- [x] **Technical support contact** — `AboutSupportSection` ("Supporto tecnico") opens a version/build-stamped `mailto:info@digitalyogin.com`, with a fallback alert if Mail is unavailable.

---

## PHASE 8 — In-app update alert (2026-06-09)

- [x] **Remote-config version gating** — `AppVersionConfig` + `SemanticVersion` (lenient, crash-proof), `AppVersionService` (fetches `…/functions/v1/app-config`), `AppVersionStore` (`@Observable`, launch check), `AppUpdateSheet` (soft/forced UI). Wired into `DiteloSuiTettiApp` launch + `ContentView` presentation.
- [x] **Soft vs forced** — `current < minimum` → blocking full-screen cover (no dismiss); `current < latest` → dismissible sheet ("Aggiorna ora" / "Più tardi"), dismissal persisted per `latest` version.
- [x] **Fail-safe** — config fetch error logged and ignored; the app is never blocked. Verified live (endpoint 404 → graceful skip).

**Pending (backend)**:
- [ ] Deploy the `app-config` Edge Function returning `{ latest_ios_version, minimum_ios_version, app_store_url, message }` (see API_CONTRACT "App Version Config"). Set the real App Store ID in `app_store_url`.

---

## PHASE 7 — RC polish: PDF cards + editorial fallback (2026-06-09)

- [x] **Premium `LinkedDocumentCard`** — white card, 52pt tinted PDF icon tile, "PDF" pill, 3-line title, optional description, right open icon, soft-red "Apri PDF" action strip (≥46pt), VoiceOver "Apri documento PDF, [title]". Used in Article + Event detail. `NavigationLink → PDFReaderView` unchanged.
- [x] **Official editorial fallback image** — `dst_fallback_logo` brand asset shown by `RemoteImageView` when `imageURL == nil` or load fails (Home/Articoli lists, featured cards, Article/Event detail headers). No more gradient placeholders for editorial content; `ImageCache` retained for valid URLs; fallback diagnostics added.
- [x] **iPad readable-width parity** — `EventDetailView` content constrained to `DT.readableMaxWidth` (matches `ArticleDetailView`); no card clipping under Dynamic Type.
- [x] **Android conversion docs** — `ANDROID_CONVERSION_GUIDE.md`, `APP_FLOW.md`, `DATA_MODELS.md`, `UI_COMPONENTS.md` (new) + updated context/contract/readme.

**Pending (carry-over)**:
- [ ] Backend `mobile_documents_public` / `file_url` fix verification (re-host the 7 legacy/dead document URLs — see PHASE 6)
- [ ] APNs production killed-app push QA
- [ ] App Store screenshot final pass
- [ ] Android Kotlin / Jetpack Compose conversion (the build itself)

---

## PHASE 6 — Document URL Audit (2026-06-09)

**Trigger**: Documenti tab failed with HTTP 404 on some PDFs while Article/Event attachments and PDFKit worked fine.

**Findings**: Of 25 documents, 18 use Supabase storage URLs (all `206 application/pdf` — work); 7 use legacy `www.suitetti.org` URLs — 6 dead `wp-content/*.pdf` (`404`, confirmed not a UA block) and 1 WordPress article permalink that serves HTML, not a PDF.

**Root cause**: Backend data — 7 documents were never migrated to Supabase storage and still carry dead/HTML legacy URLs. The payload exposes only one `url` field per document, so the app had no alternate field to fall back to. This is **not** an iOS/PDFKit bug.

**Fix applied (iOS)**:
- [x] `[DocumentURL]` (title + url) log before every PDF open
- [x] `[DocumentPDF]` (status + mime) log on every download; HTML/non-PDF bodies throw `invalidContent` instead of a blank viewer
- [x] `DocumentDTO` resolves across all URL field variants and **prefers a direct `.pdf` URL over a page URL**; non-PDF resolution logs `[DocumentURL] ⚠️` at decode

**Pending (backend remediation)**:
- [ ] **Re-host 6 dead-PDF documents** to the `document-files` Supabase bucket and update each `url` (slugs: `amicus-curiae-scienza-vita`, `opinione-ex-art-6-nig-esserci-oss-bioetica-siena`, `legge-bilancio-2024-proposte-network-sui-tetti`, `pdl-partecipazione-proposte-bilancio-2025`, `legge-bilancio-2025-proposte-network-sui-tetti`, `lettera-ministro-schillaci-vita-fine-vita`)
- [ ] **Fix `incostituzionalita-del-fine-vita`** — store the real PDF URL or reclassify as a web-link document

---

## In Progress / Verification needed

- [ ] **Verify `APNS_ENV = production` in Supabase secrets** — TestFlight / App Store require production APNs endpoint (`api.push.apple.com`); backend must not use sandbox endpoint for distribution builds
- [ ] **Attachment E2E test** — insert a row in `public.allegati`, open app, sync, confirm `LinkedDocumentCard` appears in article/event detail view
- [ ] **TestFlight Release Candidate QA** — full regression: all tabs, dark mode, offline mode, push notification flow
- [ ] **Latest-content ordering — real-device QA (2026-06-09 fix)** — delete app → fresh install → Home shows latest article → Articoli first item is latest publication → Documenti shows latest PDFs → open a PDF → pull-to-refresh keeps order → relaunch keeps order. (Sort/decoding verified on the iPhone 17 Pro simulator against the live endpoint; on-device pass still pending.)

---

## Pending — App Store Launch

- [ ] **App Store screenshots — iPhone** — 6.9" (iPhone 17 Pro Max) and 6.1" (iPhone 17) required; use `--screenshots` launch mode with `AppStorePreviewData`
- [ ] **App Store screenshots — iPad** — 12.9" required; same screenshot mode
- [ ] **App Store metadata** — Italian and English app description, subtitle, keywords, support URL (`https://www.suitetti.org`), privacy URL (`https://www.suitetti.org/privacy`)
- [ ] **App Store Connect app record** — create record, set age rating (4+), pricing (free), primary category (News), secondary (Lifestyle)
- [ ] **APNs killed-app push test** — install TestFlight build, force-quit app, trigger push from Supabase, confirm banner appears and deep link resolves on tap
- [ ] **PrivacyInfo.xcprivacy — Xcode target membership** — file exists at `DiteloSuiTetti/PrivacyInfo.xcprivacy`; must be dragged into Xcode Project Navigator and checked for "DiteloSuiTetti" target membership
- [ ] **App Icon dark/tinted variants** — designer must provide 1024×1024 PNGs; add to `AppIcon.appiconset/` and set `filename` in `Contents.json`
- [ ] **Release notes** — first release Italian copy; 400 char limit for App Store "What's New"

---

## v1.1 Candidates (post-launch)

- [ ] Spotlight Search — `CSSearchableItem` per article/document; search from Home Screen
- [ ] Universal Links — `apple-app-site-association` on `www.suitetti.org`; `onOpenURL` in `ContentView`
- [ ] Widgets — `AppIntents` + `WidgetKit`; latest article or upcoming event widget
- [ ] Advanced iPad sidebar — `NavigationSplitView` three-column layout for iPad Pro
- [ ] Delta sync activation — pass `serverTime` as `?since=` on subsequent syncs
- [ ] Background content refresh — `BGAppRefreshTask` + silent push `content-available: 1`
- [ ] Share sheet on article detail
- [ ] Search / favorites
- [ ] Android / Kotlin implementation (see `docs/ANDROID_HANDOFF.md`)
- [ ] Dynamic Island Live Activity (stretch)
