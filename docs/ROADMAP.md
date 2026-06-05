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
- [x] **Resilient/lossy decoding** — `Lossy<T>` wrapper for per-item decode isolation; per-section fallback to `[]` in `EditorialSyncResponseDTO`; `Date.distantPast` fallback on malformed dates; NSLog always on for decode failures
- [x] **SyncLogger + SyncDiagnosticsView** — 50-entry ring buffer; Console.app visible in all builds; 5-tap access from SosteniView
- [x] **APNs push token registration** — device token registered on first launch; `PushTokenRegistrationService` deduplicates; `register-push-token` Edge Function deployed
- [x] **Privacy Manifest** — `PrivacyInfo.xcprivacy` created (UserDefaults, Device ID/AppFunctionality); **must be added to Xcode target manually**
- [x] **Screenshot Capture Mode** — `--screenshots` launch argument; `AppStorePreviewData` injects fixtures; bypasses network + onboarding
- [x] **App icon** — 1024×1024 marketing icon present
- [x] **Onboarding** — 3-slide onboarding with animated bokeh backgrounds; `@AppStorage("hasSeenOnboarding")` gate
- [x] **URLCache hardening** — `URLCache.shared` enlarged to 50 MB memory / 200 MB disk to prevent image eviction between tabs
- [x] **Dark Mode navigation title fix** — all cream-background screens use `.toolbarBackground(.brandCream)` + `.toolbarColorScheme(.light)` so large titles render dark in both modes (`ArticoliView`, `DocumentiView`, `EventiView`, `AboutView`, `SosteniView`)
- [x] **Article/Event PDF attachment support (iOS)** — full pipeline: `AttachmentDTO` → `RelatedDocument` → `CachedArticle/CachedEvent` (SwiftData JSON column) → `LinkedDocumentCard` in detail views
- [x] **Backend: allegati migration deployed** — `public.allegati` table with polymorphic `parent_type + parent_id`, soft delete, `is_mobile_visible`, delta-sync trigger
- [x] **Backend: sync-editorial attachments deployed** — `attachments: []` on every article and event; never null
- [x] **Backend: send-apns-push deployed** — production APNs push with `content_type`, `content_id`, `url`
- [x] **Backend: notify-content-published deployed** — triggers on new content publish; constructs `https://www.suitetti.org/{articoli|eventi|documenti}/{slug}` URLs

---

## In Progress / Verification needed

- [ ] **Verify `APNS_ENV = production` in Supabase secrets** — TestFlight / App Store require production APNs endpoint (`api.push.apple.com`); backend must not use sandbox endpoint for distribution builds
- [ ] **Attachment E2E test** — insert a row in `public.allegati`, open app, sync, confirm `LinkedDocumentCard` appears in article/event detail view
- [ ] **TestFlight Release Candidate QA** — full regression: all tabs, dark mode, offline mode, push notification flow

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
