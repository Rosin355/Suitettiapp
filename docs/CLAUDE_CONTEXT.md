# CLAUDE_CONTEXT — Ditelo sui Tetti iOS

> Snapshot of project architecture and conventions for AI-assisted sessions.
> Read this before starting any task.

---

## Identity

- **App name**: Ditelo sui Tetti (internal codename: SUITETTI)
- **Platform**: iOS 26+ (SwiftUI native, iPhone + iPad)
- **Developer**: Digital Yogin srl
- **Style**: Civic, editorial, trustworthy — iOS 26 Liquid Glass direction
- **Current stage**: v1.0 Release Candidate — App Store pre-submission

---

## Architecture

### State containers (`@Observable`, `@MainActor`)
- `ArticleStore` — articles list, category filter, sync state
- `EventStore` — events list, sync state
- `DocumentStore` — documents list, sync state
- All stores injected via `.environment()` from root

### Sync layer
- `EditorialSyncCoordinator` — orchestrates full + delta sync
- `APIClient` — `URLSession` + `JSONDecoder.editorial` (`.convertFromSnakeCase` + custom ISO8601 date strategy with `Date.distantPast` fallback)
- `EditorialCacheRepository` — SwiftData persistence layer; populates stores on cold launch
- `SyncLogger` — ring-buffer log sink (50 entries); `NSLog` output always on

### Navigation
- `ContentView` → `TabView` with four tabs: `.home`, `.articoli`, `.documenti`, `.chiSiamo`
- Each tab is a `NavigationStack`
- No UIKit navigation controllers

### Design tokens (`DT` enum)
| Token | Value |
|---|---|
| `cornerRadius` | 22 |
| `smallCorner` | 14 |
| `padding` | 16 |
| `sectionSpacing` | 12 |
| `topBarContentOffset` | 62 |
| `readableMaxWidth` | 820 |

### iPad adaptation rules
- All list screens constrain content to `DT.readableMaxWidth` (820pt) and center it on `horizontalSizeClass == .regular`
- Pattern: `.frame(maxWidth: isIPad ? DT.readableMaxWidth : .infinity).frame(maxWidth: .infinity)`
- ArticoliView: `GeometryReader`-computed left panel (`max(280, min(400, geo.size.width × 0.40))`) + unlimited detail panel (HStack split); `isEmbedded: true` for `ArticleDetailView`
- Hero background always full-bleed; brand lockup constrained to `HeroSizeConfig.brandMaxWidth` (580pt on iPad)
- Navigation: iPhone uses `NavigationLink` + `.navigationTransition(.zoom)`; iPad panel uses `onSelect` closure + `selectedArticle` binding
- Do NOT use `NavigationSplitView` nested inside a `NavigationStack` — use the HStack split pattern instead
- Stage Manager: never use `frame(width: N)` for panels; always compute from `GeometryReader` with a min/max clamp

### Accessibility rules
- Tap targets: all interactive controls must have a minimum 44×44pt hit area
- VoiceOver: list rows (`ArticleListRow`, `EventRow`) use `.accessibilityElement(children: .combine)` + explicit `.accessibilityLabel`
- Contrast: use `.brandGray` (not `.brandGrayLight`) for metadata text
- Reduce Motion: ALL animations that run on appear or in response to user actions must check `@Environment(\.accessibilityReduceMotion)`

### Navigation bar dark-mode fix
All cream-background screens use:
```swift
.toolbarBackground(.brandCream, for: .navigationBar)
.toolbarColorScheme(.light, for: .navigationBar)
```
Using `.brandCream` (solid) instead of `.ultraThinMaterial` ensures the title text renders dark in both light and dark mode.
Applied to: `ArticoliView`, `DocumentiView`, `EventiView`, `AboutView`, `SosteniView`.

### Key components
- `GCard<Content>` — generic card with tint background, border, shadow
- `SectionHeader` — `.padding(.horizontal, 20)` (all About content uses `aboutHPad = 20` to match)
- `RemoteImageView` — `AsyncImage` with branded gradient fallback
- `CategoryChip` — pill label for article categories
- `HomeTopBar` — floats over hero, shows condensed brand on scroll
- `EmptyStateView` — illustrated empty/error state: icon badge (88pt circle), title, subtitle, up to 2 actions
- `LinkedDocumentCard` — compact card for a linked PDF; `RelatedDocument` model (`Codable`); NavigationLink to `PDFReaderView` when URL present; disabled state when nil
- `AttachmentDTO` — flexible decoder for attachment items; handles Italian/English field names; never throws

---

## Screens

| Tab | Root View | Sub-views |
|---|---|---|
| Home | `HomeView` | `HomeHeroSection`, `HeroTickerView`, `HomeFeaturedArticlesSection`, `HomeEventsSection`, `HomeQuoteSection` |
| Articoli | `ArticoliView` | `ArticlesFilterBar`, `ArticlesListSection`, `ArticleDetailView` |
| Documenti | `DocumentiView` | `DocumentDetailView`, `PDFReaderView` |
| Chi siamo | `AboutView` | `AboutHeroSection`, `AboutMissionSection`, `AboutSupportCTA`, `AboutSettingsSection`, `AboutDeveloperSection`; `SosteniView` (5-tap diagnostics entry) |

---

## Attachments (article + event PDF documents)

Articles and events both support `relatedDocuments: [RelatedDocument]`.

**iOS pipeline**: `ArticleDTO` / `EventDTO` decode `attachments` (or `allegati`) JSON array → `AttachmentDTO` → `RelatedDocument` → stored as `relatedDocumentsJSON: String?` in `CachedArticle` / `CachedEvent` (SwiftData) → shown as `LinkedDocumentCard` in detail views.

**Backend**: `sync-editorial` returns `attachments: []` on every article and event. The `allegati` table stores attachments with a polymorphic `parent_type + parent_id` design. See `docs/API_CONTRACT.md`.

**Detail view sections**:
- `ArticleDetailView`: "Documenti allegati" section with `LinkedDocumentCard` per attachment
- `EventDetailView`: "Documenti dell'evento" section with `LinkedDocumentCard` per attachment

---

## Hero section (Home)

`HomeHeroSection` → `HeroBackgroundView` (animated `MeshGradient`) + `HeroBrandView` + `HeroStatsView`.

`HeroBrandView` accepts responsive font-size parameters computed by `HeroSizeConfig.responsive()` based on device screen height.

Screen height tiers:
| Height | Device | titleSize | subtitleSize |
|---|---|---|---|
| < 700 pt | iPhone SE | 54 | 48 |
| 700–820 pt | iPhone mini | 62 | 56 |
| 820–880 pt | iPhone 15/16 non-Max | 66 | 60 |
| 880–1000 pt | iPhone Max/Plus | 72 | 66 |
| ≥ 1000 pt | iPad | 88 | 78 |

---

## Backend

- **Sync endpoint**: `https://kbswgeliohnpwopzzzpc.supabase.co/functions/v1/sync-editorial`
- **Delta sync**: append `?since=<ISO8601_date>`
- Public, no auth required
- Returns `server_time`, `articles[]` (with `attachments: []`), `events[]` (with `attachments: []`), `documents[]`
- **Push token registration**: `POST /functions/v1/register-push-token`
- **Send push**: `POST /functions/v1/send-apns-push` (deployed, production APNs)
- **Notify on publish**: `notify-content-published` Edge Function (deployed)
- **Push public URLs**: `https://www.suitetti.org/{articoli|eventi|documenti}/{slug}`

---

## Security constraints (permanent)

- No service-role keys in the iOS app
- APNs: device token registration is implemented and deployed; `aps-environment = production` in entitlements
- `APNS_ENV` Supabase secret must be set to `production` for TestFlight/App Store pushes to arrive
- Do not change local notification behavior
- Do not change onboarding flow

---

## Fonts

- System font: `.system(size:weight:)` for all UI text
- Georgia italic: `Font.georgiaItalic(_:)` extension — used for hero subtitle and quote section

---

## Contact / emails

- General: `segreteria@suitetti.org`
- Privacy/legal only: `privacy@suitetti.org`

---

## Screenshot Capture Mode

Launch with `--screenshots` to enter screenshot mode for App Store Connect capture:
- Bypasses onboarding, skips network sync, skips push notification registration
- Injects `AppStorePreviewData` — 4 articles, 3 events (Oct–Nov 2026), 3 documents; deterministic UUIDs
- `DiteloSuiTettiApp.isScreenshotMode` flag; `loadContent()` early-returns with preview data

---

## App Store Readiness

| Item | Status |
|---|---|
| `PrivacyInfo.xcprivacy` | ✅ Created — **must be added to Xcode target manually** (drag into Project Navigator → check DiteloSuiTetti target membership) |
| APNs `aps-environment = production` | ✅ In entitlements |
| App Transport Security | ✅ All HTTPS, no exceptions |
| App Icon 1024×1024 | ✅ |
| App Icon dark/tinted | ⚠️ JSON entries present, PNG files missing — designer action required |
| Version display in About | ✅ `AboutDeveloperSection` shows `CFBundleShortVersionString` + `CFBundleVersion` |
| `NSCalendarsFullAccessUsageDescription` | ✅ In xcodeproj `INFOPLIST_KEY_` |
| Screenshot Capture Mode | ✅ `--screenshots` launch argument |
| Dark Mode navigation title fix | ✅ All cream-background screens use `.brandCream` toolbar background |
| Attachment support (iOS) | ✅ Full pipeline: DTO → model → cache → UI |
| Attachment backend deployed | ✅ `allegati` migration + `sync-editorial` updated |
| SwiftData offline cache | ✅ All three content types persisted |
| Push token registration | ✅ Registered on launch, deduped in UserDefaults |
| APNs production backend | ✅ `send-apns-push` deployed; verify `APNS_ENV=production` in Supabase secrets |

---

## Remaining RC items

1. Verify `APNS_ENV = production` in Supabase project secrets
2. TestFlight killed-app push delivery test
3. E2E attachment test: insert a row in `allegati`, sync app, verify `LinkedDocumentCard` appears
4. Capture App Store screenshots (use `--screenshots` mode)
5. Prepare App Store metadata (Italian + English)
6. Final TestFlight RC QA pass
7. Submit for App Review

---

## File layout (current)

```
DiteloSuiTetti/
  Configuration/      AppEnvironment.swift, DT.swift
  Design/             Color+Brand.swift, Font+Brand.swift, ViewModifiers.swift
  Models/             Article.swift, Event.swift, Document.swift, AttachmentDTO.swift, DTOs
  Fixtures/           PreviewData.swift, AppStorePreviewData.swift
  Components/
    Common/           GCard, SectionHeader, CategoryChip, RemoteImageView, EmptyStateView
    Home/             HeroTickerView, HomeTopBar
    Documents/        LinkedDocumentCard.swift
  Screens/
    Home/             HomeView, HomeHeroSection, HeroBrandView, HeroBackgroundView, HeroStatsView
    Articles/         ArticoliView, ArticlesListSection, ArticleDetailView
    Documents/        DocumentiView, DocumentDetailView, PDFReaderView
    Events/           EventiView, EventDetailView
    About/            AboutView, SupportDonationSheet, PrivacyPolicyView, RateAppSheet, SocialLinksSheet
    Support/          SosteniView, SyncDiagnosticsView
  Services/           EditorialSyncCoordinator, APIClient, EditorialCacheRepository
  Utilities/          SyncLogger
  PrivacyInfo.xcprivacy   ← must be in DiteloSuiTetti target membership
supabase/
  functions/
    sync-editorial/   index.ts  ← deployed; returns attachments on articles + events
    register-push-token/
  migrations/
    20260527000000_create_push_device_tokens.sql
    20260605000001_create_allegati.sql  ← deployed
docs/
  CLAUDE_CONTEXT.md   ← this file
  ROADMAP.md
  CHANGELOG_AI.md
  API_CONTRACT.md
  PUSH_NOTIFICATIONS_QA.md
  APP_STORE_CHECKLIST.md
  ANDROID_HANDOFF.md
  ANDROID_IMPLEMENTATION_PLAN.md
  APP_STORE_OWNERSHIP.md
```
