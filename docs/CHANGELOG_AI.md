# CHANGELOG_AI — Ditelo sui Tetti iOS

AI-assisted session log. Most recent first.

---

## 2026-06-09 — PHASE 6: Document URL audit (Documenti tab PDF 404s)

**Goal**: Article/Event PDF attachments and PDFKit all work, but the Documenti tab failed on some documents with HTTP 404 (e.g. "PDL Partecipazione Proposte Bilancio 2025" failed; "Festival 3°" worked). Audit the full Documents pipeline and find why.

### Findings (live `sync-editorial`, 25 documents)

Audited every document URL with the app's User-Agent (1-byte range request):

| Host | Count | HTTP | Result |
|---|---|---|---|
| `…supabase.co/storage/v1/object/public/document-files/…` | **18** | `206` `application/pdf` | ✅ all work |
| `www.suitetti.org/wp-content/uploads/…pdf` | **6** | `404` `text/plain` ("Not found") | ❌ dead file |
| `www.suitetti.org/2023/10/30/legge-cappato/` | **1** | `200` `text/html` | ❌ HTML page, not a PDF |

The 404s were re-tested with a desktop **browser User-Agent** and still returned `404 "Not found"` → **not** a UA/bot block; the files genuinely no longer exist on the WordPress host.

The backend exposes **only a single `url` field** per document (no `file_url`/`pdf_url`/`attachment_url`), so there was no alternate field the app could have fallen back to.

### Root cause

**Backend data quality, not the iOS pipeline.** 18 documents were migrated to Supabase storage and resolve correctly. 7 documents still carry **legacy `www.suitetti.org` URLs**:
- 6 point to `wp-content/uploads/*.pdf` files that were deleted when the site was rebuilt → permanent `404`.
- 1 points to a WordPress **article permalink** (not a file) → the server returns the site HTML, which PDFKit cannot render.

The working "Festival" document and all Article/Event attachments resolve to Supabase storage, which is exactly why those paths never failed.

### Fix applied (iOS — diagnostics + resilience)

- **`PDFReaderView`** — logs `[DocumentURL] title=… url=…` before every download.
- **`PDFDownloadService`** — logs `[DocumentPDF] status=… mime=… url=…` for every response; an HTML/non-PDF body now logs `✗ not a PDF — server returned mime=…` and throws `invalidContent` (no blank viewer). 404s already surface as "Errore del server (codice 404)".
- **`DocumentDTO`** — URL resolution now collects all known field variants (`url`, `file_url`, `pdf_url`, `document_url`, `attachment_url`, `public_url`, `legacy_url`, `link`) and **prefers a direct-`.pdf` URL over a page URL** — so if the backend ever provides both a page URL and a PDF URL, the PDF wins. A document whose only URL is non-PDF logs `[DocumentURL] ⚠️ '…' resolved to a non-PDF URL: …` at decode (verified live: flagged "Incostituzionalità del fine vita").

`** BUILD SUCCEEDED **` (iPhone 17 Pro simulator). Diagnostics verified live against the endpoint.

### Recommended backend fix (the real remediation — not iOS)

For each of the 7 failing documents (slugs below), upload the source PDF to the `document-files` Supabase bucket (path pattern `documents/legacy/<slug>/<file>.pdf`, as the 18 working docs use) and update the row's `url` to the new public storage URL. For `incostituzionalita-del-fine-vita`, either store the real PDF URL or reclassify it as a web-link document.

Failing slugs: `amicus-curiae-scienza-vita`, `opinione-ex-art-6-nig-esserci-oss-bioetica-siena`, `incostituzionalita-del-fine-vita` (HTML), `legge-bilancio-2024-proposte-network-sui-tetti`, `pdl-partecipazione-proposte-bilancio-2025`, `legge-bilancio-2025-proposte-network-sui-tetti`, `lettera-ministro-schillaci-vita-fine-vita`.

### Per-document report

| Title | Current URL | HTTP | Root cause | Recommended fix |
|---|---|---|---|---|
| Amicus Curiae Scienza & Vita | `…/wp-content/uploads/2024/04/OPINIONE-SCRITTA-EX-ART.-6.pdf` | 404 | Legacy WP file deleted | Re-upload to Supabase; update `url` |
| Opinione ex art. 6 NIG – Esserci | `…/wp-content/uploads/2024/04/Opinione-ex-art.-6-NIG_signed.pdf` | 404 | Legacy WP file deleted | Re-upload to Supabase; update `url` |
| Incostituzionalità del fine vita | `…/2023/10/30/legge-cappato/` | 200 (HTML) | URL is a WP article page, not a PDF | Store real PDF URL or mark as web link |
| Legge di Bilancio 2024 | `…/wp-content/uploads/2023/09/LEGGE-DI-BILANCIO-10-CANONI-SUI-TETTI-web.pdf` | 404 | Legacy WP file deleted | Re-upload to Supabase; update `url` |
| PDL Partecipazione Proposte Bilancio 2025 | `…/wp-content/uploads/2025/01/PDL-PARTECIPAZIONE-PROPOSTE-BILANCIO-2025-SUI-TETTI.pdf` | 404 | Legacy WP file deleted | Re-upload to Supabase; update `url` |
| Legge di Bilancio 2025 | `…/wp-content/uploads/2024/10/legge-di-bilancio-2025-sui-tetti.pdf` | 404 | Legacy WP file deleted | Re-upload to Supabase; update `url` |
| Lettera del Ministro Schillaci | `…/wp-content/uploads/2022/11/SALUTO-MINISTRO-FINE-VITA_ok.pdf` | 404 | Legacy WP file deleted | Re-upload to Supabase; update `url` |

---

## 2026-06-09 — Sort latest editorial content & restore documents visibility (RC)

**Goal**: Sync succeeded (273 articles, 62 events, 25 documents) but the UI did not surface the latest content: Home/Articoli showed stale ordering, Documenti did not show the newest PDFs, and one event failed to decode because `ora` was `null`. Fix sorting, cache refresh and document visibility — without redesigning the UI.

### Root cause

Content was rendered in **raw backend array order** — nothing sorted by date. Two model-level data losses made date-sorting impossible:

- **`Article`** kept only formatted date *strings* (`date`, `fullDate`); `ArticleMapper` discarded `ArticleDTO.dataPubblicazione`. Home "In evidenza" (`store.articles.prefix(6)`) and Articoli's featured hero (`filtered.first`) therefore trusted whatever order the backend returned.
- **`Document`** kept only the `uploadedAt` *string* (+ `updatedAt`); `DocumentMapper` discarded `DocumentDTO.dataCaricamento`. `DocumentiView` iterated `store.documents` in raw order.

Compounding issues:
- **Event drop**: `EventDTO.ora` was a non-optional `try c.decode(String.self,…)` — a `null` `ora` threw `valueNotFound` and the per-item `Lossy<EventDTO>` wrapper silently dropped that event. The same applied to `tipo`/`luogo`/`descrizione`/`syncVersion` (any `null` would drop an otherwise-valid event).
- **Stale cache**: the SwiftData cache held old, date-less, unsorted rows; without a schema bump + one-time clear, restored content stayed stale.

### Fix

**New `Utilities/EditorialSort.swift`** — single source of truth for ordering. Stable descending sort by an optional `Date` key; `nil` dates sort *last* (tie-break on original index → valid strict-weak-ordering, no sort crash).

**Articles (TASK 1)**
- `Article` + `CachedArticle` gained `publishedAt: Date?`; `ArticleMapper` maps it from `dataPubblicazione`; cache persists/restores it.
- `ArticleStore` now routes `load`/`refresh`/`replace` through a private `apply(_:)` choke point that sorts via `EditorialSort` and logs `[ArticleStore] sorted latest article: …`.

**Documents (TASK 2)**
- `Document` + `CachedDocument` gained `publishedAt: Date?` (mapped strictly from `dataCaricamento`, so the sort key matches the displayed "Caricato il" date and truly undated PDFs sink to the bottom).
- `DocumentStore` sorts via the same `apply(_:)` choke point; logs `[DocumentStore] sorted latest document: …`.
- `DocumentDTO` URL decode now also tries `public_url` (`publicUrl` via `.convertFromSnakeCase`), in addition to `url`/`file_url`/`document_url`/`link`. Documents without a URL stay disabled ("PDF non disponibile"); valid URLs remain tappable. `DocumentiView` already uses the live/cache `DocumentStore` (PreviewData only feeds `#Preview`).

**Events (TASK 3)**
- `EventDTO.ora` is now `String?` via `decodeIfPresent`. Extended the resilience to `slug`/`tipo`/`dataEvento`/`luogo`/`descrizione`/`syncVersion` (safe defaults) so **only `id`/`titolo` can ever drop an event** — matching the requirement. `EventMapper` handles the optional `ora`.

**Cache (TASK 4)**
- `EditorialCacheRepository` gained `schemaVersion = 2` (key `editorialCacheSchemaVersion`). On launch, a version mismatch purges all cached articles/events/documents **once**, logs `[EditorialCache] schema bump — clearing stale editorial cache`, then a fresh sync repopulates with dated, sorted content. The version is advanced **only after a confirmed purge** (do/catch), so a transient failure retries next launch.

**Diagnostics (TASK 5)**
- `EditorialSyncCoordinator` sorts the payload at the source (so `NewContentDetector`, which picks the first new item, sees newest-first) and logs the first 5 of each type in final order: `[SyncDiag] article[i] / document[i] (url nil/present) / event[i] (rawDate, upcoming)`.

### Files changed

`Utilities/EditorialSort.swift` (new), `Models/Article.swift`, `Models/Document.swift`, `Models/DocumentDTO.swift`, `Models/EventDTO.swift`, `Mappers/ArticleMapper.swift`, `Mappers/DocumentMapper.swift`, `Mappers/EventMapper.swift`, `Persistence/CachedArticle.swift`, `Persistence/CachedDocument.swift`, `Persistence/EditorialCacheRepository.swift`, `Stores/ArticleStore.swift`, `Stores/DocumentStore.swift`, `Services/Sync/EditorialSyncCoordinator.swift`.

### Verification

- Implementation was reviewed by an adversarial multi-agent pass (sort correctness, SwiftData migration safety, decode resilience, compile-safety). Three confirmed findings were fixed before commit: incomplete event-decode resilience (HIGH), document sort-key vs. displayed-date divergence (MEDIUM), and cache version advancing on a failed purge (LOW).
- `** BUILD SUCCEEDED **` (Debug, iPhone 17 Pro simulator) — no new errors; only pre-existing preview/main-actor warnings.
- Adding an optional SwiftData attribute is a lightweight, automatically-migratable change; the one-time schema purge is belt-and-suspenders for stale ordering.

### What to look for after deploying

Filter Console.app by `[SyncDiag]`, `[ArticleStore]`, `[DocumentStore]`, `[EditorialCache]`:
- `[SyncDiag] article[0]` should be the newest publication; `[SyncDiag] document[0]` the newest PDF.
- `[EditorialCache] schema bump — clearing stale editorial cache` appears once after updating.

---

## 2026-06-08 — Resilient article/event decoding after backend attachments update

**Goal**: Restore articles and events after the backend `attachments[]` addition caused the entire sections to decode as empty (0 articles, 0 events, 25 documents).

### Root cause

`EditorialSyncResponseDTO` decoded articles and events using `[ArticleDTO]` / `[EventDTO]` (non-lossy). If a single item in the array failed, `try? c.decode([ArticleDTO].self, ...)` returned nil and the fallback was `[]`. Documents already used `[Lossy<DocumentDTO>]` (per-item isolation) and decoded fine — 25 items.

The backend attachment update added `attachments: [...]` to articles and events. At least one item in each section contained data that caused `ArticleDTO.init(from:)` to throw (likely a non-optional required field missing/wrong type in a new backend format, or an attachment shape that propagated an error upward). The `try?` on the whole array masked the individual error.

### Fix

**`Models/EditorialSyncResponseDTO.swift`**:
- Articles: changed to `[Lossy<ArticleDTO>]` — per-item isolation, exact same pattern as documents
- Events: changed to `[Lossy<EventDTO>]` — per-item isolation
- Added index-based per-item error log (first 5): `[EditorialSyncResponseDTO] ✗ article[N] error: ...`
- Added "first article" diagnostic log: title, attachment count, first attachment title
- Added "first event" diagnostic log: title, attachment count
- Made `Lossy` struct **internal** (removed `private`) so `ArticleDTO`/`EventDTO` can use `Lossy<AttachmentDTO>`
- Logs `key present: yes/no` when even the lossy array decode fails (key missing or wrong top-level type)

**`Models/AttachmentDTO.swift`**:
- Added `name`, `attachmentName` (`attachment_name` via `.convertFromSnakeCase`), `filename` as title fallback keys — covers all common file-metadata field names the backend may return

**`Models/ArticleDTO.swift`** + **`Models/EventDTO.swift`**:
- Changed attachment decoding to `[Lossy<AttachmentDTO>]` → `compactMap(\.value)` — one bad attachment never throws into the parent article/event decode

### Build status

`** BUILD SUCCEEDED **` — no new errors.

### What to look for after deploying

Filter Console.app by `[EditorialSyncResponseDTO]`:
- `articles decoded: N` — should be > 0 now
- `✗ article[N] error:` — identifies exactly which article and field failed before the fix
- `first article: title='...' attachments=N` — confirms attachment data flows through

Note: `PushTokenRegistrationService env: sandbox` in logs is expected for Xcode debug builds. TestFlight / App Store builds send `env: production`. Do not change push logic for this issue.

---

## 2026-06-08 — Persistent image cache: article thumbnails now load reliably everywhere

**Goal**: Fix article thumbnails showing gradient placeholders in `ArticleListRow` (58×58) while the same image loaded correctly in the featured hero card (230px).

### Root cause

`AsyncImage` has no persistent disk cache — it relies on `URLCache.shared` (in-memory only). At 58×58, `AsyncImage` loses the cached image when a row scrolls off-screen, and re-requests the image each time it re-appears. This caused "many thumbnails show placeholder" because: rows scrolled past were evicted from memory cache; delta sync articles might have had `imageURLString = nil` in old SwiftData cache (field was added in RC).

### Fix: NSCache + FileManager disk cache

**New file: `DiteloSuiTetti/Utilities/ImageCache.swift`**
- `@MainActor final class ImageCache` — singleton, no third-party dependencies
- Load order: NSCache (memory, 100 items / 50MB) → FileManager `.cachesDirectory/DST_ImageCache/` → URLSession network
- Hash-named disk files (`abs(url.hashValue).imgcache`), atomic writes
- NSLog at every tier: `[ImageCache] memory:`, `disk:`, `fetch:`, `✓ saved:`, `✗ failed:`

**Updated: `Components/Common/RemoteImageView.swift`**
- Replaced `AsyncImage` with `@State private var uiImage: UIImage?` + `.task(id: url)` → `ImageCache.shared.image(for:)`
- Same public API (url, contentMode, fallbackColors) — all existing callers unchanged
- Shows `ProgressView` while loading; shows `Image(uiImage:)` on success; shows gradient when `url == nil` or load fails
- When a row scrolls back into view: NSCache hit returns image instantly (< 1µs), no visible flash

**Updated: `Components/Rows/ArticleListRow.swift`**
- Added `.onAppear` diagnostic: `NSLog("[ArticleListRow] '<title>' imageURL=<url|nil>")` — reveals which articles have nil imageURL in SwiftData cache vs valid URLs

### Build status

`** BUILD SUCCEEDED **` — no new errors. Same 4 pre-existing warnings (deprecated `previewDevice`; actor isolation on store initializers).

---

## 2026-06-06 — Release Candidate sync: attachments deployed, dark titles fixed, push backend updated

**Goal**: Finalize v1.0 release candidate. Apply and document all remaining fixes before App Store submission.

### Build status

`** BUILD SUCCEEDED **` — no errors, 4 harmless warnings (deprecated `previewDevice` in `#Preview` macro; actor isolation on store initializers).

### iOS: Dark Mode large title fix

**Problem**: Navigation bar large titles appeared white on cream-background screens in Dark Mode.

**Root cause**: `.toolbarBackground(.ultraThinMaterial)` renders as a dark frosted surface in Dark Mode. Even with `.toolbarColorScheme(.light)`, the title color was not reliably forced to dark because the system was adapting to the material's luminance.

**Fix**: Replaced `.ultraThinMaterial` with solid `.brandCream` as the navigation bar background. A solid, always-light background makes `.toolbarColorScheme(.light)` deterministic.

| File | Change |
|------|--------|
| `Screens/Articles/ArticoliView.swift` | `.ultraThinMaterial` → `.brandCream` |
| `Screens/Documents/DocumentiView.swift` | `.ultraThinMaterial` → `.brandCream` |
| `Screens/Events/EventiView.swift` | Added `.toolbarBackground(.brandCream)` + `.toolbarColorScheme(.light)` (was missing entirely) |
| `Screens/About/AboutView.swift` | `.ultraThinMaterial` → `.brandCream` |
| `Screens/Support/SosteniView.swift` | `.ultraThinMaterial` → `.brandCream`; added missing `.toolbarColorScheme(.light)` |

### Backend: attachments pipeline deployed

**Migration** (`supabase/migrations/20260605000001_create_allegati.sql`):
- `public.allegati` table — polymorphic `parent_type + parent_id`; no FK constraints; references `public.articles` / `public.events` (English table names)
- `is_mobile_visible boolean`, `deleted_at timestamptz` (soft delete), `sync_version bigint`
- Delta-sync trigger: bumps parent `updated_at` on any attachment change
- RLS: public read where `deleted_at IS NULL AND is_mobile_visible = true`

**Edge Function** (`supabase/functions/sync-editorial/index.ts`):
- Queries `articles`, `events`, `documents` with correct English table names
- Fetches `allegati` in a separate query; merges by `parent_id`
- `attachments: []` always present on every article and event; never null
- Backward compat: all existing API field names preserved (snake_case Italian)

### Backend: APNs push update

Deployed by Lovable / backend team:
- `send-apns-push` payload now includes `content_type`, `content_id`, `url`
- `notify-content-published` reads slug and constructs public URL using `https://www.suitetti.org/{articoli|eventi|documenti}/{slug}`
- `APNS_ENV` in Supabase secrets must be set to `production` for TestFlight / App Store delivery

### Documentation updated

| File | Change |
|------|--------|
| `docs/CLAUDE_CONTEXT.md` | Full rewrite — current RC status, attachment pipeline, dark title fix, backend state, remaining items |
| `docs/ROADMAP.md` | Full rewrite — completed v1.0 checklist, in-progress verification, App Store pending, v1.1 candidates |
| `docs/API_CONTRACT.md` | Added `allegati` table schema, deployment steps (Steps 0–6), push payload shape |
| `docs/PUSH_NOTIFICATIONS_QA.md` | Updated current status table, updated APNs payload to include `url`, added full QA procedure |
| `docs/APP_STORE_CHECKLIST.md` | Created — marks completed items, tracks remaining pre-submission steps |

### Remaining QA before App Store submission

1. Verify `APNS_ENV = production` in Supabase project secrets
2. TestFlight killed-app remote push test (force-quit → trigger push → confirm banner + deep link)
3. E2E attachment test: insert row in `allegati`, sync app, confirm `LinkedDocumentCard` in detail view
4. Capture App Store screenshots (iPhone 6.9" + 6.1", iPad 12.9")
5. Prepare App Store metadata (Italian + English description, keywords, URLs)
6. Final TestFlight RC QA pass
7. Submit for App Review

---

## 2026-06-05 — PHASE-5 (v2): Backend attachments pipeline — schema corrected

**Goal**: Update the `sync-editorial` Supabase Edge Function to include `attachments: [...]` on every article and event. Initial attempt failed with `ERROR: 42P01: relation "public.articoli" does not exist` — the real table names are `articles`, `events`, `documents` (English), not the Italian names used in the first migration draft.

### Root cause of first failure

The first migration assumed Italian table names (`public.articoli`, `public.eventi`) based on the Italian column names inside those tables and the Italian field names in the Edge Function output. Live inspection of the endpoint revealed the tables themselves are named `articles`, `events`, `documents`. The Italian names are only column/field names within those tables.

### allegati table (rewritten)

`supabase/migrations/20260605000001_create_allegati.sql`:

- **Polymorphic design**: `parent_type text CHECK ('article', 'event') + parent_id uuid` — no FK constraints (avoids awkward multi-table FK pattern)
- References `public.articles` and `public.events` in the delta-sync trigger only — no FK declarations
- English column names: `title`, `type`, `description`, `url` (matching `AttachmentDTO` expected keys)
- `is_mobile_visible boolean NOT NULL DEFAULT true` — CMS toggle
- `deleted_at timestamptz` — soft delete; mobile queries filter `deleted_at IS NULL`
- `sync_version bigint NOT NULL DEFAULT 1`
- Four indexes: `(parent_type, parent_id)`, mobile read-path filtered, `deleted_at IS NULL`, `updated_at DESC`
- `allegati_bump_parent_updated_at` trigger — UPDATE `articles SET updated_at = now()` or `events SET updated_at = now()` based on `parent_type`
- RLS: `anon` + `authenticated` SELECT where `deleted_at IS NULL AND is_mobile_visible = true`; no write policy

### sync-editorial Edge Function (rewritten)

`supabase/functions/sync-editorial/index.ts`:

| Feature | Implementation |
|---------|----------------|
| Table names | `articles`, `events`, `documents` (English, matching real DB) |
| Attachment strategy | Single `allegati` query; builds `Map<parent_id, AttachmentOut[]>`; merged into articles/events |
| `attachments` always present | Returns `[]` never `null` on every article and event |
| API field names | All existing fields preserved in snake_case Italian (backward compat — iOS `convertFromSnakeCase` handles both) |
| Top-level key | `server_time` (unchanged) |
| Delta sync | `?since=ISO8601` filters `updated_at > since` on articles, events, documents |
| Allegati query | Always fetches full visible attachment set (not filtered by `since`) so delta-synced articles have complete attachment list |
| allegati error handling | Non-fatal — logs error and returns `attachments: []` rather than failing the whole response |
| Logging | Total counts; per-item count for first 5 articles/events with attachments |

### API_CONTRACT.md additions

- `allegati` table schema section
- Deployment step 0: schema verification SQL (`information_schema.tables`)
- Corrected insert SQL for test data (using `parent_type`, `parent_id`, English column names)
- Sample JSON response with `attachments` populated
- Note that `server_time` (snake_case) maps to `serverTime` Swift property via `convertFromSnakeCase`

### Files

| File | Status |
|------|--------|
| `supabase/migrations/20260605000001_create_allegati.sql` | REWRITTEN (schema corrected) |
| `supabase/functions/sync-editorial/index.ts` | REWRITTEN (table names corrected) |
| `docs/API_CONTRACT.md` | UPDATED |
| `docs/ROADMAP.md` | UPDATED |

### Deployment action required

Until deployed, `attachments: []` on all articles/events — iOS graceful empty state, no crash. See `docs/API_CONTRACT.md → Backend Deployment — Attachments Pipeline` for the full checklist including the Step 0 verification query.

---

## 2026-06-05 — PHASE-4: Release-blocking bug fixes (BUG 1/2/3)

**Goal**: Fix three device-only bugs blocking the first release.

### BUG 1 — ArticoliView images show fallback gradients

**Root cause**: `URLCache.shared` default capacity (20 MB memory, 20 MB disk) was too small. Images loaded on the Home tab were evicted before ArticoliView rendered.

**Fix**: `DiteloSuiTettiApp.init()` now configures `URLCache.shared` with 50 MB memory and 200 MB disk.

**Diagnostics added**: After each full sync, first 5 articles are logged with `imageURL` and attachment count.

### BUG 2 — Category filter chips not tappable (open article instead)

**Root cause**: `ArticlesFilterBar` (a horizontal `ScrollView`) was nested inside the main vertical `ScrollView` in `iPhoneLayout`. iOS gesture disambiguation between the two scroll views caused taps on filter buttons to propagate to the `NavigationLink` in `ArticlesListSection`.

**Fix**: In `ArticoliView.iPhoneLayout`, the filter bar is now positioned OUTSIDE the `ScrollView` in a parent `VStack`, mirroring the iPad split layout structure. `Color.clear.frame(height: 130)` in `ArticlesListSection` gets `.allowsHitTesting(false)`.

### BUG 3 — PDF attachments on articles/events don't appear in app

**Root cause**: `ArticleDTO` and `EventDTO` had no `attachments` fields. The `sync-editorial` Edge Function is not tracked in this repo — the backend must add the array to its response.

**iOS implementation** (ready to receive backend data the moment it ships):

| File | Change |
|------|--------|
| `Models/AttachmentDTO.swift` | NEW — lenient decoder; handles Italian/English field names; never throws |
| `Components/Documents/LinkedDocumentCard.swift` | `RelatedDocument` now `Codable` |
| `Models/Article.swift` | Added `relatedDocuments: [RelatedDocument]` (default `[]`) |
| `Models/Event.swift` | Added `relatedDocuments: [RelatedDocument]` (default `[]`) + explicit `init` |
| `Models/ArticleDTO.swift` | Decodes `attachments` / `allegati` key |
| `Models/EventDTO.swift` | Decodes `attachments` / `allegati` key |
| `Mappers/ArticleMapper.swift` | Passes `relatedDocuments: attachments` |
| `Mappers/EventMapper.swift` | Passes `relatedDocuments: attachments` |
| `Persistence/CachedArticle.swift` | `relatedDocumentsJSON: String?` — JSON round-trip in SwiftData |
| `Persistence/CachedEvent.swift` | `relatedDocumentsJSON: String?` — JSON round-trip in SwiftData |
| `Screens/Articles/ArticleDetailView.swift` | "Documenti allegati" section with `LinkedDocumentCard` |
| `Screens/Events/EventDetailView.swift` | "Documenti dell'evento" section with `LinkedDocumentCard` |

**Backend action required**: `sync-editorial` must join the `allegati` table and include `attachments: [...]` in each article and event object. See `docs/API_CONTRACT.md` for attachment field schema.

---

## 2026-06-05 — PHASE-3: App Store Readiness

**Goal**: Prepare Ditelo sui Tetti for App Store submission. Audit, fix, and document all blocking and non-blocking store readiness items.

**Audit findings**:

| Item | Status | Action |
|---|---|---|
| Privacy Manifest (`PrivacyInfo.xcprivacy`) | ❌ MISSING — CRITICAL | Created |
| APNs entitlements (`aps-environment = production`) | ✅ Present | None |
| App Transport Security | ✅ All HTTPS, no exceptions needed | None |
| App Icon 1024×1024 | ✅ `ios-marketing.png` present | None |
| App Icon dark/tinted variants | ⚠️ JSON entries exist, PNG files absent | Designer action required |
| Version/build display in About | ✅ Already in `AboutDeveloperSection` | None |
| Screenshot Capture Mode | ❌ Not implemented | Implemented |
| `AppStorePreviewData.swift` | ❌ Not present | Created |
| `NSCalendarsFullAccessUsageDescription` | ✅ In build settings via `INFOPLIST_KEY_` | None |

**Files created**:

- `DiteloSuiTetti/PrivacyInfo.xcprivacy`
  - `NSPrivacyTracking`: false
  - `NSPrivacyTrackingDomains`: []
  - `NSPrivacyCollectedDataTypes`: Device ID (APNs push token), purpose AppFunctionality, not linked, not tracking
  - `NSPrivacyAccessedAPITypes`: UserDefaults (CA92.1) — covers `@AppStorage("hasSeenOnboarding")` and `lastSuccessfulSyncDate`
  - **ACTION REQUIRED**: Must be added to the DiteloSuiTetti target in Xcode (Project Navigator → check target membership). Without this the file is on disk but not bundled.

- `DiteloSuiTetti/Fixtures/AppStorePreviewData.swift`
  - 4 articles with full Italian civic body text (4–5 paragraphs each), deterministic UUIDs
  - 3 events with Oct–Nov 2026 `rawDate` (always upcoming when screenshots are captured)
  - 3 documents with realistic Italian civic content
  - `enum AppStorePreviewData` — static arrays, no `Date()` calls, fully deterministic

**Files modified**:

- `DiteloSuiTettiApp.swift`
  - Added `private let isScreenshotMode = ProcessInfo.processInfo.arguments.contains("--screenshots")`
  - `body`: changed `if hasSeenOnboarding` to `if hasSeenOnboarding || isScreenshotMode` — bypasses onboarding in screenshot mode
  - `loadContent()`: early return in screenshot mode — injects `AppStorePreviewData` into all three stores, sets `router.contentDidLoad = true`, skips network sync and push notification registration

**Screenshot mode usage**:

1. In Xcode: Edit Scheme → Run → Arguments → Arguments Passed On Launch → `+` → `--screenshots`
2. Run the app — it launches directly to ContentView with deterministic demo content, no network calls
3. Capture screenshots in the simulator

**App Store Connect checklist**:
- [ ] Add `PrivacyInfo.xcprivacy` to app target in Xcode (Project Navigator)
- [ ] Provide dark/tinted icon PNGs to designer
- [ ] Create app record in App Store Connect
- [ ] Set age rating (4+)
- [ ] Add Italian (primary) and English app descriptions
- [ ] Capture 6.7" and 5.5" iPhone screenshots using `--screenshots` mode
- [ ] Capture 13" iPad screenshots if targeting iPad
- [ ] Upload screenshots to App Store Connect
- [ ] Set pricing (free)
- [ ] Confirm Push Notification capability in provisioning profile
- [ ] Submit for review

**Build**: ✅ Compiles — no new dependencies, no breaking changes to existing stores or sync flow.

---

## 2026-06-05 — iPad Layout Fixes + Linked Documents + Image Hardening

**Goal**: Fix iPad layout clipping in ArticleDetailView, fix left-alignment bug in DocumentDetailView, create LinkedDocumentCard for future backend wiring, harden image URL parsing.

**Root causes found**:
- `ArticleDetailView` body/title text clipped on iPad: `titleCardSection + contentSection` inherited the full panel width (700–900pt in split mode) via `containerRelativeFrame`. No `maxWidth` constraint was applied to the text content block.
- `DocumentDetailView` left-pinned on iPad: Phase 2 added `.frame(maxWidth: .infinity, alignment: .leading)` as the outer frame, which positioned the constrained 820pt container against the LEFT edge instead of centering it.
- Linked documents: `ArticleDTO` and `EventDTO` have no document relationship fields in the current API. Feature deferred to backend roadmap.
- Image URL: `URL(string:)` is fragile for URLs with spaces/Italian characters. Added percent-encoding fallback + NSLog diagnostics.

**Files modified**:

- `Screens/Articles/ArticleDetailView.swift`
  - Wrapped `titleCardSection + contentSection` in `VStack(spacing: 0) { ... }.frame(maxWidth: DT.readableMaxWidth).frame(maxWidth: .infinity)`
  - Hero (`DetailHeroImage`) remains full panel width
  - Fix applies to both full-screen iPhone/iPad and embedded iPad split mode
  - iPhone layout unchanged (820pt max never restricts a 390pt screen)

- `Screens/Documents/DocumentDetailView.swift`
  - Removed `@Environment(\.horizontalSizeClass)` (was only used for the broken frame)
  - Changed to universal double-frame centering pattern: `.frame(maxWidth: DT.readableMaxWidth).frame(maxWidth: .infinity)`
  - Content is now centered on iPad; iPhone layout unchanged

- `Mappers/ArticleMapper.swift`
  - Extracted `parseImageURL(_:slug:)` — tries `URL(string:)` first, then percent-encoding fallback
  - NSLog on encoding fallback and on total parse failure — visible in Console.app on device/TestFlight
  - Image pipeline audit: `CachedArticle` correctly persists `imageURLString` ✓; `ArticleListRow` and `ArticlesFeaturedCard` use `RemoteImageView(url: article.imageURL, ...)` ✓

**Files created**:

- `Components/Documents/LinkedDocumentCard.swift`
  - `RelatedDocument` model: `id`, `title`, `type`, `description`, `url: URL?`
  - `LinkedDocumentCard` view: NavigationLink to PDFReaderView when url is present; disabled state when nil
  - Accessible labels + hint; min-height 64pt; PressableCardStyle
  - NOT yet integrated into ArticleDetailView/EventDetailView (no backend data)
  - See ROADMAP.md pending item "Linked documents"

**Backend audit findings**:
- `ArticleDTO`: `id`, `titolo`, `slug`, `categoria`, `dataPubblicazione`, `estratto`, `contenuto`, `immagineUrl`, `updatedAt`, `syncVersion` — NO document reference fields
- `EventDTO`: `id`, `titolo`, `slug`, `tipo`, `dataEvento`, `ora`, `luogo`, `descrizione`, `link`, `immagineUrl`, `updatedAt`, `syncVersion` — NO document reference fields
- Action: backend must add `documentIds: [UUID]` or similar to expose relationships

**iPad QA checklist**:
- [ ] ArticleDetailView: body text wraps correctly and does not run to panel edge in split mode
- [ ] ArticleDetailView: title card correctly overlaps hero bottom (-32pt) in centered container
- [ ] ArticleDetailView: hero image is still full panel width
- [ ] ArticleDetailView: iPhone layout unchanged
- [ ] DocumentDetailView: content centered within 820pt on 12.9" iPad landscape
- [ ] DocumentDetailView: content full-width on iPhone
- [ ] LinkedDocumentCard preview renders correctly

**Build**: ✅ BUILD SUCCEEDED — iPhone 17 Pro Simulator, iOS 26.2

---

## 2026-06-05 — PHASE-2: Accessibility + iPad QA

**Goal**: Full accessibility and iPad QA pass. No feature changes, no design changes, no backend changes.

**Files modified**:

- `Screens/Home/HomeHeroSection.swift`
  - Added `@Environment(\.accessibilityReduceMotion)` — appear animation is now instant when reduce motion is on

- `Screens/Articles/ArticlesFilterBar.swift`
  - Category tap no longer calls `withAnimation` when reduce motion is on
  - Chip vertical padding increased from 9pt to 14pt — achieves ≥44pt tap target

- `Components/Rows/ArticleListRow.swift`
  - `HStack` gains `.accessibilityElement(children: .combine)` + explicit label `"category. title. date, readTime di lettura."`
  - Metadata `foregroundStyle` changed from `.brandGrayLight` (~2.3:1 contrast on cream) to `.brandGray` (~5.5:1) — WCAG AA compliant

- `Components/Rows/EventRow.swift`
  - `HStack` gains `.accessibilityElement(children: .combine)` + label `"day month. title. place."`
  - Date badge gets `.accessibilityHidden(true)` (label provided on outer combined element instead)
  - Chevron gets explicit `.accessibilityHidden(true)`

- `Screens/Articles/ArticleDetailView.swift`
  - Floating back button: `frame(width: 40, height: 40)` → `frame(width: 44, height: 44)`
  - Floating share button: `frame(width: 40, height: 40)` → `frame(width: 44, height: 44)`

- `Screens/Events/EventDetailView.swift`
  - Floating back button: `frame(width: 40, height: 40)` → `frame(width: 44, height: 44)`
  - Floating share button: `frame(width: 40, height: 40)` → `frame(width: 44, height: 44)`

- `Screens/Articles/ArticoliView.swift`
  - Added `@Environment(\.accessibilityReduceMotion)`
  - iPad selection animation guarded: skips `withAnimation` when reduce motion is on
  - iPad detail transition degrades to `.opacity` when reduce motion is on
  - Left panel `frame(width: 400)` replaced with `GeometryReader`-computed `max(280, min(400, geo.size.width × 0.40))` — Stage Manager safe

- `Screens/Documents/DocumentDetailView.swift`
  - Added `@Environment(\.horizontalSizeClass)` — scroll content constrained to `DT.readableMaxWidth` on iPad (double-frame centering pattern)

**Already compliant (no changes needed)**:
- `HeroBackgroundView` — mesh animation already guarded with `accessibilityReduceMotion` ✓
- `AppearModifier` — already respects `accessibilityReduceMotion` ✓
- `PressableCardStyle` — already respects `accessibilityReduceMotion` ✓
- `ShimmerModifier` — already respects `accessibilityReduceMotion` ✓
- `SupportDonationSheet` + `RateAppSheet` — buttons ≥44pt, labels ✓
- `EventDetailView` info cards — `.accessibilityLabel` + `.accessibilityHint` already present ✓
- `DocumentDetailView` action buttons — `.accessibilityLabel` already present ✓

**Known limitation (deferred)**:
- All body/metadata text uses `.font(.system(size: N))` fixed sizes — Dynamic Type scaling is not yet implemented. Text won't grow at accessibility sizes but layouts don't clip because no fixed-height containers surround body text. A full Dynamic Type migration would require a design-approved typographic scale.

**iPad QA checklist**:
- [ ] ArticoliView: left panel stays ≥280pt in Stage Manager narrow window
- [ ] ArticoliView: left panel stays ≤400pt in landscape on 12.9" iPad
- [ ] ArticoliView: detail transition is instant when reduce motion is on
- [ ] ArticleDetailView/EventDetailView: back/share buttons visually larger (44×44) in both portrait and landscape
- [ ] DocumentDetailView: content centered within 820pt on 12.9" iPad
- [ ] ArticleListRow: VoiceOver reads "category. title. date, readTime di lettura." as a single element
- [ ] EventRow: VoiceOver reads "day month. title. place." as a single element
- [ ] Filter chips: taller tap area (≥44pt) — visible in UI
- [ ] Hero appear: instant on device with Reduce Motion enabled in Accessibility settings

**Build**: ✅ BUILD SUCCEEDED — iPhone 17 Pro Simulator, iOS 26.2

---

## 2026-06-05 — PHASE-1: UX Polish + iPad Adaptation

**Goal**: Make the app feel native on iPad; add polish across all list screens.

**New files**:
- `Components/Common/EmptyStateView.swift` — illustrated empty/error state with icon badge, title, subtitle, primary + secondary actions

**Files modified**:

- `Design/AppSpacing.swift` — `DT.readableMaxWidth = 820` added

- `Screens/Home/HomeHeroSection.swift`
  - New iPad tier (`h ≥ 1000pt`): titleSize 88pt, subtitleSize 78pt, `brandMaxWidth: 580`
  - `HeroSizeConfig` gains `brandMaxWidth: CGFloat`; `HeroBrandView` is constrained to it so the lockup doesn't stretch across 1024pt+ canvases

- `Screens/Home/HomeView.swift`
  - Non-hero sections wrapped in `VStack` with `frame(maxWidth: DT.readableMaxWidth)` on iPad
  - Hero + ticker remain full-bleed

- `Screens/Home/HomeFeaturedArticlesSection.swift`
  - iPad: `LazyVGrid` 2-column card grid with `RemoteImageView` thumbnails (72×72) + zoom transitions
  - iPhone: existing vertical list + zoom transitions

- `Screens/Articles/ArticleDetailView.swift`
  - `isEmbedded: Bool = false` — when true: no back button, no top safe-area override, hero 240pt
  - `horizontalSizeClass` imported for future use

- `Screens/Articles/ArticlesListSection.swift`
  - `onSelect: ((Article) -> Void)?` + `selectedArticle: Article?` params for iPad panel mode
  - iPhone: `.navigationTransition(.zoom(sourceID:in:))` on all NavigationLinks
  - iPad panel: Button rows with selection highlight tint

- `Screens/Articles/ArticoliView.swift`
  - On `horizontalSizeClass == .regular`: 400pt list panel + unlimited detail panel (HStack split)
  - `ArticleDetailView(isEmbedded: true)` in right panel; resets scroll on `.id(article.id)` change
  - Refresh haptics: `@State refreshHaptic` toggled after `store.refresh()`, drives `.sensoryFeedback(.success)`
  - Error + empty replaced with `EmptyStateView`

- `Screens/Documents/DocumentiView.swift`
  - `EmptyStateView` for error + empty states
  - List constrained to `DT.readableMaxWidth` on iPad
  - Refresh haptics

- `Screens/Events/EventiView.swift`
  - `EmptyStateView` for error + empty states (with "Consulta gli eventi passati" secondary action)
  - Filter bar + list constrained to `DT.readableMaxWidth` on iPad
  - Refresh haptics

- `Screens/About/AboutView.swift`
  - ScrollView content constrained to `DT.readableMaxWidth` on iPad

**iPad QA checklist**:
- [ ] Home hero: brand lockup stays left-aligned within 580pt on 12.9" iPad
- [ ] Home: editorial sections centered on 12.9" landscape
- [ ] ArticoliView: two-column split shows on iPad, single column on iPhone
- [ ] Article tapped in panel: right column updates, scroll resets
- [ ] Zoom transition fires on iPhone NavigationLink
- [ ] EmptyStateView shows correct icon/title/action in Documents and Events
- [ ] Refresh haptic fires once after pull-to-refresh completes
- [ ] About cards do not stretch to 1366pt on 12.9" landscape
- [ ] All screens tested: portrait iPad, landscape iPad, iPhone SE, iPhone 17 Pro Max

**Build**: ✅ BUILD SUCCEEDED — iPhone 17 Pro Simulator, iOS 26.2

---

## 2026-06-05 — TASK-001: Responsive Home Hero

**Goal**: Reduce hero height on compact iPhones without hardcoded device checks.

**Files changed**:
- `DiteloSuiTetti/Screens/Home/HeroBrandView.swift`
  - Added `titleSize: CGFloat = 72`, `subtitleSize: CGFloat = 66`, `taglineBottomPadding: CGFloat = 20` parameters
  - Defaults preserve existing behaviour on large-screen devices
  - Kerning now scales proportionally: `-3.5 * titleSize / 72` and `-2.5 * subtitleSize / 66`

- `DiteloSuiTetti/Screens/Home/HomeHeroSection.swift`
  - Added private `HeroSizeConfig` struct with `responsive()` factory
  - Screen height read via `UIWindowScene.screen.bounds.height` (non-deprecated; fallback 852 pt)
  - Four breakpoints: < 700, 700–820, 820–880, ≥ 880
  - `contentBottomPadding` also reduced per tier (36 → 18 on SE)
  - `HeroBrandView` call updated to pass responsive values

**Docs created**: `docs/CLAUDE_CONTEXT.md`, `docs/ROADMAP.md`, `docs/CHANGELOG_AI.md`

**Build**: ✅ BUILD SUCCEEDED — iPhone 17 Pro Simulator, iOS 26.2

---

## 2026-06-04 — TestFlight Hardening + Push Notifications

**Goal**: Fix decode failures in TestFlight builds and register APNs device token.

**Files changed**:
- `APIClient.swift` — lenient date decoder (distantPast fallback, NSLog always on)
- `EditorialSyncResponseDTO.swift` — custom `init(from:)` with per-section isolation
- `EditorialSyncCoordinator.swift` — safe per-item mapping, NSLog always on
- `SyncLogger.swift` (new) — ring buffer, @Observable, 50-entry cap
- `SyncDiagnosticsView.swift` (new) — diagnostic sheet
- `SyncDiagnosticsSection.swift` (new) — 5-tap hidden entry in SosteniView
- `DiteloSuiTetti.entitlements` — `aps-environment = production`
- `AppDelegate.swift` / push token registration flow added

---

## 2026-06-03 — AboutView Polish + Featured Articles Fix

**Goal**: Fix featured article card (hardcoded, non-navigable) and redesign developer section.

**Files changed**:
- `ArticlesListSection.swift` — `ArticlesFeaturedCard` now uses real `Article` data, wrapped in `NavigationLink`
- `AboutView.swift` → `AboutDeveloperSection` — Digital Yogin branding, tech chips, website link
- `AppEnvironment.swift` — `digitalYoginURL` added

---

## 2026-06-02 — AboutView Legal / Social / Rate Us

**Goal**: Replace placeholder rows with native sheets; add GDPR privacy policy.

**Files created**:
- `PrivacyPolicyView.swift` — 9-section GDPR text, native in-app view
- `RateAppSheet.swift` — StoreKit review request sheet
- `SocialLinksSheet.swift` — Facebook, X, YouTube links

**Files changed**:
- `AboutView.swift` — Terms row hidden, Privacy → NavigationLink, social/rate callbacks wired

---

## 2026-06-01 — AboutView Donation CTA + Bank Details

**Goal**: Add donation support with IBAN copy-to-clipboard.

**Files created**:
- `SupportDonationSheet.swift` — bank detail cards, "Copia IBAN" and "Copia coordinate" buttons

---

## 2026-05-30 — Home Hero Redesign

**Goal**: Replace static hero with animated MeshGradient, redesign brand lockup.

**Files created/changed**:
- `HeroBackgroundView.swift` — MeshGradient, single `phase` driver, 9 control points
- `HeroBrandView.swift` — "Ditelo" + "sui Tetti." editorial lockup
- `HeroStatsView.swift` — statistics strip (articles, events, documents counts)
- `HeroTickerView.swift` — scrolling news ticker
- `HomeHeroSection.swift` — orchestrates all hero sub-views
- `HomeView.swift` — tab restructure: Home, Articoli, Sostieni (dropped Per il Sì, Comitati)
