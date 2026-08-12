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

## Post-1.0.2 — Dynamic featured event (2026-08-12)

Replaced the hardcoded Festival spotlight with a CMS-driven banner. Editors pick what is
promoted; the app never needs a release to change it.

- [x] **Backend audit** — no featured field existed anywhere for events (`events` table, the
      `mobile_events_public` view, `sync-editorial`, or the live payload). The web home banner
      is hardcoded too. The admin's "Evento in evidenza" toast was mislabeled copy on the
      `is_mobile_visible` (sync-visibility) toggle — reusing that flag would have deleted
      events from the apps.
- [x] **Migration written** — `events.is_featured boolean NOT NULL DEFAULT false` + partial
      index + the column appended to `mobile_events_public`. Additive and backward compatible;
      `sync-editorial` needs no change because it spreads `select("*")` from the view.
- [x] **Admin toggle** — exclusive "in evidenza" switch in `AdminEditorialEvents.tsx`
      (featuring one event clears the previous), plus a fix for the mislabeled toast.
- [x] **iOS pipeline** — `isFeatured` through `EventDTO` → `Event` → `EventMapper` →
      `CachedEvent` → `EventStore`, defaulting to `false` at every hop.
- [x] **`EventStore.featuredEvent`** — derived on every read, never persisted; deterministic
      resolution + warning when several events are flagged.
- [x] **`HomeFeaturedEventCard` + `HomeFeaturedEventSection`** — reusable card, whole-card tap
      to the **native** `EventDetailView`, brand-artwork fallback, one merged VoiceOver
      element, Dynamic Type via `@ScaledMetric`.
- [x] **Old Festival CTA removed from Home** — `HomePromoCard` retained as a component but no
      longer rendered.
- [x] **Cache-signature fix** — `is_featured` now feeds `contentSignature`, so clearing the
      flag rewrites the cache and the banner cannot reappear on next launch.
- [x] **Crash-proofed the cache** — `EditorialCacheRepository` no longer force-tries its
      `ModelContainer`; it rebuilds an unmigratable store and degrades gracefully.
- [x] **QA** — 23/23 checks on a harness compiling the real sources (scenarios A–F, live
      payload regression); runtime verified on simulator; banner verified visually on iPad.
- [x] `** BUILD SUCCEEDED **` — iPhone 17 Pro + iPad Pro 13-inch (M5).

**Blocked / follow-up**:
- [ ] **Apply the migration to production.** The Supabase CLI account available locally has no
      privileges on project `kbswgeliohnpwopzzzpc`, so it could not be applied from here. Until
      it runs, `is_featured` is absent from the payload, every event decodes as `false`, and
      the banner stays hidden — the app is shipping-safe in that state.
- [ ] After applying, regenerate `src/integrations/supabase/types.ts` from the live schema
      (the column was hand-added there to keep the web build type-checking).

---

## Post-1.0.2 — Evergreen Home hero + Festival spotlight (2026-07-02)

Website (`suitetti.org`) published post-festival videos + extra material. The app was made evergreen while surfacing the 3° Festival properly — **hybrid**: an in-app WebView spotlight card now, a native detail later (Option B, backend-gated).

- [x] **Evergreen hero stats** — `HeroStatsView` third stat `16 giu · 3° Festival` → `Italia · Rete civica`; no date-bound value can go stale. Small-label contrast lifted (white `0.56` → `0.72` on brand red).
- [x] **Removed dead `HomeStatsStrip.swift`** — legacy pre-refactor strip, referenced nowhere, still carrying the stale festival stat.
- [x] **Stale CTA removed** — deleted the commented `HomeReferendumCTA` ("Scopri l'evento del 16 giugno"); replaced by the reusable, generic `HomePromoCard`.
- [x] **Festival spotlight card** — Home `HomePromoCard` ("SPECIALE · 3° Festival — rivivi video e materiali"); tapping opens `AppEnvironment.festivalURL` in the **external browser** (SwiftUI `openURL`). Whole card is a ≥44pt tap target with a combined VoiceOver label + hint.
- [x] **In-app web layer (reusable, retained)** — `InAppWebView` has a `WKNavigationDelegate` coordinator exposing `isLoading`/`loadError` (ignores `NSURLErrorCancelled`, converts HTTP 4xx/5xx to the error state); `WebPageView` shows a real loading spinner + graceful error state; `WebSheet` wraps it in a `NavigationStack` with a Close button. **Kept as components but no longer wired to a screen** — the festival card now opens in the external browser instead.
- [x] **Onboarding slide 2 evergreen** — dropped `3°` / `FESTIVAL 2026` / "Ti aspettiamo" (future tense for a now-past event); now `IL FESTIVAL` / `FESTIVAL` / "Ci vediamo sui tetti". Accessibility label updated to match.
- [x] **Hero brand VoiceOver** — `HeroBrandView` lockup now reads as one header element instead of three fragments.
- [x] `** BUILD SUCCEEDED **` (iPhone 17 Pro simulator); no new warnings. Article/event sync, PDF opening, push, share links, and the app-config update alert are all untouched.

**Backend / follow-up**:
- [x] **`AppEnvironment.festivalURL` set** — `https://www.suitetti.org/progetti/festival-umano-tutto-intero` (verified live 2026-07-02: the festival hub "Rivivi il 3° Festival dell'Umano Tutto Intero" with videos, gallery, and program/press downloads). Opened in the **external browser** by the Home festival card.
- [ ] **Option B (native FestivalDetailView) is backend-gated** — events expose no `video_url` and no event↔article relation. See `API_CONTRACT.md` → "Proposed: Festival / Project content".

---

## Release 1.0.2 (build 2) — 2026-06-17

Versioned release bundling PHASES 6–10. `MARKETING_VERSION = 1.0.2`, `CURRENT_PROJECT_VERSION = 2`.
Highlights: reliable editorial sync + resilient article/event/document decoding (no dropped content),
canonical `suitetti.org` share links, technical-support email section, premium PDF cards + brand
fallback image, Home festival CTA disabled (future banner slot), in-app update system via `app-config`,
Android push infra documented (iOS APNs unchanged), backend stale-content mitigation. See `RELEASE_NOTES.md`.

**Still pending (backend / submission)**: deploy `app-config` Edge Function; re-host the 7 legacy/dead
document URLs (PHASE 6); APNs production killed-app push QA; App Store screenshots + metadata.

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

- [ ] **Native `FestivalDetailView` / `ProjectDetailView` (Option B)** — cover + description + **video player** + **related articles** + related PDFs + external link. **Blocked on backend**: events expose no `video_url` and no event↔article relation. `EventDetailView` already covers cover/description/PDFs/link, so this is largely additive. See `API_CONTRACT.md` → "Proposed: Festival / Project content".
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
