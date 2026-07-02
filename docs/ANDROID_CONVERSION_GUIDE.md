# Android Conversion Guide — Ditelo sui Tetti

> Living document for porting the native iOS SwiftUI app to native Kotlin + Jetpack Compose. Verified against the iOS codebase on 2026-06-09; update it as the Android port advances.

This is the **primary** reference for the Android engineer. It maps every load-bearing iOS pattern to a concrete Kotlin/Compose equivalent, with the exact field names, fallback rules, and edge cases the iOS app already handles in production (273 articles, ~63 events, 25 documents live). Do not invent fields or screens beyond what is documented here — the API and the screen inventory are authoritative.

---

## 1. Overall architecture mapping

The iOS app is a thin, content-first client over a single Supabase Edge Function. State lives in three `@Observable @MainActor` stores, injected into the view tree via SwiftUI `.environment(...)`. Networking is `URLSession` + `Codable`; the offline cache is SwiftData; images are a custom two-tier cache. The Android port should keep the same boundaries.

| iOS concept | iOS detail | Android equivalent |
|---|---|---|
| `@Observable @MainActor` store (`ArticleStore`, `EventStore`, `DocumentStore`) | Holds `articles/events/documents`, plus `isLoading`, `isRefreshing`, `errorMessage`, `offlineMessage`. All mutation routes through one `apply(...)` choke point that re-sorts. | `ViewModel` exposing immutable UI state as `StateFlow<UiState>`. Keep the single choke-point: one reducer that sorts before emitting. |
| `.environment(store)` injection | Stores created once at app root, read by descendant views. | Hilt-scoped `@HiltViewModel` obtained with `hiltViewModel()`, or a `CompositionLocal` for cross-cutting singletons. Prefer Hilt for the three stores. |
| Service layer (`EditorialServiceProtocol`, `LiveEditorialService`) | Protocol-backed so stores are testable with fakes. | A `Repository` interface + `LiveEditorialRepository` impl, provided by Hilt. |
| SwiftData cache (`EditorialCacheRepository` + `Cached*` models) | Cache-first cold launch, then background sync; schema-versioned with one-time purge. | **Room** for the three cached tables + **DataStore (Preferences)** for `lastSuccessfulSyncDate`, schema version, and `hasSeenOnboarding`. |
| `URLSession` + `JSONDecoder` (`APIClient`) | Snake-case conversion, custom multi-format date decoding, retry with backoff. | **Retrofit (OkHttp)** or **Ktor** + **kotlinx.serialization** (recommended) or Moshi. Custom `KSerializer<Instant>` for the date strategy. |
| `ImageCache` (NSCache + FileManager) + `RemoteImageView` | Memory + disk cache; brand-logo fallback. | **Coil** `AsyncImage` with memory + disk cache and an `error`/`fallback` painter. |
| `PDFKitView` + `PDFDownloadService` | Download → validate mime/extension → cache → PDFKit. | `PdfRenderer` (bundled viewer) or `WebView` / **Chrome Custom Tabs** fallback. |
| `AppEnvironment` (Info.plist-backed URLs) | Base URL + endpoint builders; ships with safe defaults. | `BuildConfig` fields per build type, wrapped in an `AppEnvironment` object. |
| `@AppStorage("hasSeenOnboarding")` | Onboarding gate. | DataStore boolean. |
| Threading: stores are `@MainActor`; network/disk hop off it implicitly | UI mutations on main actor. | `Dispatchers.Main` for UI state; `Dispatchers.IO` for network, Room, disk, PDF download. Use `viewModelScope`. |

### Store → ViewModel skeleton

```kotlin
data class ArticlesUiState(
    val articles: List<Article> = emptyList(),
    val isLoading: Boolean = false,
    val isRefreshing: Boolean = false,
    val errorMessage: String? = null,
    val offlineMessage: String? = null,
) {
    // Mirror ArticleStore.categories: ["Tutto"] + distinct categories, order preserved.
    val categories: List<String>
        get() = listOf("Tutto") + articles.map { it.category }.distinct()
}

@HiltViewModel
class ArticlesViewModel @Inject constructor(
    private val repository: EditorialRepository,
) : ViewModel() {

    private val _state = MutableStateFlow(ArticlesUiState())
    val state: StateFlow<ArticlesUiState> = _state.asStateFlow()

    // Mirrors ArticleStore.load(): only loads once, when empty.
    fun load() {
        val s = _state.value
        if (s.isLoading || s.isRefreshing || s.articles.isNotEmpty()) return
        _state.update { it.copy(isLoading = true, errorMessage = null) }
        viewModelScope.launch {
            runCatching { repository.fetchAll() }
                .onSuccess { apply(it) }
                .onFailure { e -> _state.update { it.copy(errorMessage = e.message) } }
            _state.update { it.copy(isLoading = false) }
        }
    }

    // Single choke point — every path that sets articles re-sorts (newest-first, undated last).
    private fun apply(incoming: List<Article>) {
        _state.update { it.copy(articles = EditorialSort.articlesByDateDescending(incoming)) }
    }
}
```

Collect in Compose with `val state by viewModel.state.collectAsStateWithLifecycle()`.

---

## 2. The sync layer

### Endpoint

- **Full sync (use this for v1):** `GET https://kbswgeliohnpwopzzzpc.supabase.co/functions/v1/sync-editorial` — **public, no auth header**.
- **Delta (optional):** append `?since=<ISO8601>`, e.g. `...sync-editorial?since=2026-05-19T00:00:00Z`. The iOS client builds this with `URLQueryItem`. iOS currently always calls the full endpoint in `EditorialSyncCoordinator`; `?since=` is wired for later.
- Request headers iOS sends: `Accept: application/json`, `User-Agent: DiteloSuiTetti-iOS/1.0` (use a matching Android UA), 20s timeout.
- Retry policy (`APIClient.fetchWithRetry`): up to **2 retries** with `0.5s` then `1.0s` backoff, only for retryable errors (offline, timeout, transport, or HTTP ≥ 500). Mirror this with OkHttp interceptors or a manual retry loop. Do **not** retry 4xx or decode failures.

### Response shape

Top-level JSON keys (snake_case): `server_time`, `articles[]`, `events[]`, `documents[]`. `server_time` is optional on the client side — iOS defaults it to "now" if absent/unparseable.

### Per-item lossy decoding (critical, non-negotiable)

The iOS `Lossy<T>` wrapper decodes each array element independently: **one malformed row must never empty the whole section.** With kotlinx.serialization, decode the array as `JsonArray` and map each element in a `runCatching` so a single bad object is dropped, not the section.

```kotlin
private inline fun <reified T> Json.decodeLossyList(arr: JsonArray): List<T> =
    arr.mapNotNull { el -> runCatching { decodeFromJsonElement<T>(el) }.getOrNull() }

// Usage in the response mapper:
val root = json.parseToJsonElement(body).jsonObject
val articles = json.decodeLossyList<ArticleDto>(root["articles"]?.jsonArray ?: JsonArray(emptyList()))
val events   = json.decodeLossyList<EventDto>(root["events"]?.jsonArray ?: JsonArray(emptyList()))
val documents= json.decodeLossyList<DocumentDto>(root["documents"]?.jsonArray ?: JsonArray(emptyList()))
```

If a whole section key is missing or the wrong type, treat it as an empty list (matches iOS), never a crash. Log dropped-item counts for parity with the iOS diagnostics (`"X/Y articles failed per-item decode"`).

### Multi-format date decoding

iOS tries three formats **in order**, then throws (per-item, so only that row drops):
1. ISO8601 **with fractional seconds** (`.withInternetDateTime, .withFractionalSeconds`)
2. plain ISO8601 (`.withInternetDateTime`)
3. date-only `yyyy-MM-dd` interpreted as **UTC** (Supabase `date` columns)

```kotlin
object EditorialDates {
    private val dateOnly = DateTimeFormatter.ofPattern("yyyy-MM-dd").withZone(ZoneOffset.UTC)

    fun parse(raw: String?): Instant? {
        if (raw.isNullOrBlank()) return null
        runCatching { return Instant.parse(raw) }              // handles fractional + plain ISO8601 (Z)
        runCatching { return OffsetDateTime.parse(raw).toInstant() } // offset forms
        runCatching {
            return LocalDate.parse(raw, dateOnly).atStartOfDay(ZoneOffset.UTC).toInstant()
        }
        return null  // never throw at the row level; let the field be null
    }
}

object InstantSerializer : KSerializer<Instant?> {
    override val descriptor = PrimitiveSerialDescriptor("Instant", PrimitiveKind.STRING)
    override fun serialize(e: Encoder, v: Instant?) { e.encodeString(v?.toString() ?: "") }
    override fun deserialize(d: Decoder): Instant? = EditorialDates.parse(d.decodeString())
}
```

Note iOS treats most dates as **nullable** on the model and tolerates parse failure. Do the same: a date that fails all three formats becomes `null`, the item survives and sorts last.

### Newest-first sorting (undated last, stable)

`EditorialSort` is the single source of truth for ordering — articles and documents are sorted **newest-first by their date**, undated items go **after** all dated ones, and the sort is **stable** (original index breaks ties / preserves undated order). Sort at the source so downstream logic (e.g. "newest item" detection) is correct. Events are **not** globally re-sorted in the same way — they are partitioned into upcoming / past / undated by the UI.

```kotlin
object EditorialSort {
    fun articlesByDateDescending(items: List<Article>) = byDateDescending(items) { it.publishedAt }
    fun documentsByDateDescending(items: List<Document>) = byDateDescending(items) { it.publishedAt }

    private fun <T> byDateDescending(items: List<T>, key: (T) -> Instant?): List<T> =
        items.withIndex().sortedWith(
            // dated before undated; among dated, newer first; ties & undated keep input order
            compareByDescending<IndexedValue<T>> { key(it.value) != null }
                .thenByDescending { key(it.value) }                 // nulls compare as smallest → already pushed last by the line above
                .thenBy { it.index }
        ).map { it.value }
}
```

(Equivalently, partition into dated/undated, sort the dated list by date descending with a stable sort, then concatenate undated in original order — clearer and matches iOS exactly.)

### Schema-versioned offline cache

iOS `EditorialCacheRepository` keeps `schemaVersion = 2` in `UserDefaults`. On launch, if the stored version differs, it **purges all cached rows once**, clears `lastSuccessfulSyncDate`, then advances the stored version only after a confirmed purge (so a failed purge retries next launch). Cold launch loads cache first (cache-first), then a background sync replaces it.

Android equivalent:

```kotlin
// DataStore keys
val SCHEMA_VERSION = intPreferencesKey("editorialCacheSchemaVersion")
val LAST_SYNC = longPreferencesKey("lastSuccessfulSyncDate")
const val CURRENT_SCHEMA_VERSION = 2

suspend fun migrateIfNeeded() {
    val stored = dataStore.data.first()[SCHEMA_VERSION] ?: 0
    if (stored == CURRENT_SCHEMA_VERSION) return
    runCatching {
        db.withTransaction {
            articleDao.clear(); eventDao.clear(); documentDao.clear()
        }
        dataStore.edit {
            it.remove(LAST_SYNC)
            it[SCHEMA_VERSION] = CURRENT_SCHEMA_VERSION   // advance ONLY after confirmed purge
        }
    } // on failure: leave version unchanged so it retries next launch
}
```

Cache-first flow (mirror `loadPayload` then `clearAndReplace`):

```kotlin
suspend fun fetchAll(): List<Article> = withContext(Dispatchers.IO) {
    // 1. cold launch: show cache immediately if present (caller decides emit order)
    // 2. network sync → clear & replace tables in one transaction → stamp lastSuccessfulSyncDate
    val payload = syncCoordinator.syncAll()       // throws on hard failure
    db.withTransaction {
        articleDao.clear(); articleDao.insertAll(payload.articles.map { it.toEntity() })
        // events, documents …
    }
    dataStore.edit { it[LAST_SYNC] = Instant.now().toEpochMilli() }
    EditorialSort.articlesByDateDescending(payload.articles)
}
```

When network fails but a cache exists, surface the offline warning string (iOS uses *"Contenuto non aggiornato — verifica la connessione."*) instead of clearing content.

---

## 3. Data model & DTO field reference

These field names are **authoritative** — they are exactly what the backend sends (snake_case). The iOS DTOs are resilient: only the noted hard-required fields throw; everything else falls back. Reproduce the same tolerance.

### Article (273 live)

| JSON key | Type | Required? | Notes |
|---|---|---|---|
| `id` | uuid | **required** | item dropped if missing |
| `titolo` | string | **required** | title |
| `slug` | string | **required** | deep-link key |
| `categoria` | string | **required** | filter chips |
| `data_pubblicazione` | ISO date | nullable | **sort key** (`publishedAt`); undated sorts last |
| `estratto` | string | **required** | excerpt |
| `contenuto` | string (HTML) | **required** | render HTML (iOS strips/formats it) |
| `immagine_url` | string | **nullable** | ~123 of 273 are null → brand-logo fallback |
| `updated_at` | timestamp | nullable | |
| `sync_version` | int | **required on iOS** | |
| `attachments[]` (alias `allegati[]`) | array | optional | per-item lossy; see Attachment |

### Event (~63 live)

| JSON key | Type | Required? | Notes |
|---|---|---|---|
| `id` | uuid | **required** | only hard-required field #1 |
| `titolo` | string | **required** | only hard-required field #2 |
| `slug` | string | nullable → defaults to `id` | |
| `tipo` | string | nullable → `""` | |
| `data_evento` | `YYYY-MM-DD` | nullable → `""` | date-only; empty ⇒ event shown as "undated", **never dropped** |
| `ora` | string | **nullable (common)** | null must not drop the event |
| `luogo` | string | nullable → `""` | location; Maps tap target |
| `descrizione` | string | nullable → `""` | |
| `link` | string | nullable | external link |
| `immagine_url` | string | nullable | fallback applies |
| `updated_at` | timestamp | nullable | |
| `sync_version` | int | nullable → `0` | |
| `attachments[]` (alias `allegati[]`) | array | optional | |

Event UI model derives `day`, `monthShort`, `fullDate`, `time` from `data_evento`/`ora`. iOS computes `isUpcoming` / `isPast` / `isUndated` against `Calendar.current.startOfDay(for: Date())`:

```kotlin
val today = LocalDate.now()
val isUpcoming = rawDate != null && rawDate >= today
val isPast     = rawDate != null && rawDate <  today
val isUndated  = rawDate == null
```

### Document (25 live)

| JSON key | Type | Required? | Notes |
|---|---|---|---|
| `id` | uuid | **required** | only truly required field |
| `titolo` (alias `title`) | string | nullable → `"Documento"` | |
| `slug` | string | nullable → `id` | |
| `tipo` (alias `type`) | string | nullable → `""` | |
| `categoria` (alias `category`) | string | nullable → `""` | |
| `descrizione` (alias `description`) | string | nullable → `""` | |
| `url` (+ legacy aliases `file_url`, `pdf_url`, `document_url`, `attachment_url`, `public_url`, `legacy_url`, `link`) | string | nullable | **single `url` field is current**; collect all candidates and prefer a direct `.pdf` URL over a page URL |
| `data_caricamento` (alias `created_at`) | ISO date | nullable | **sort key** (`publishedAt`) |
| `updated_at` | timestamp | nullable | |
| `sync_version` | int | nullable → `0` | |

**URL audit (known data issue):** of 25 documents, 18 resolve to working Supabase storage (`…supabase.co/storage/v1/object/public/document-files/…`); **7 carry legacy `www.suitetti.org` URLs that are dead (404) or HTML pages** — backend re-host is pending. The Android PDF reader must handle a non-PDF response gracefully (see §6).

Document URL resolution to replicate:

```kotlin
fun resolveDocumentUrl(candidates: List<String>): String? {
    fun isPdfLike(s: String) = runCatching { Uri.parse(s).lastPathSegment?.endsWith(".pdf", true) }.getOrNull() == true
    return candidates.firstOrNull(::isPdfLike) ?: candidates.firstOrNull()
}
```

### Attachment → RelatedDocument

`AttachmentDTO` is the most alias-heavy decoder; it **never throws** and defaults everything. `RelatedDocument = { id, title, type, description, url }`. Attachments carry **no date and no file size**.

| Field | Aliases (first non-empty wins) | Default |
|---|---|---|
| `id` | `id` | random UUID if missing |
| `title` | `title`, `name`, `titolo`, `attachment_name`, `filename` | `"Allegato"` |
| `type` | `type`, `tipo` | `"PDF"` |
| `description` | `description`, `descrizione` | `""` |
| `url` | `url`, `file_url`, `pdf_url`, `document_url`, `attachment_url`, `allegato_url`, `link` | `null` |

```kotlin
@Serializable
data class AttachmentDto(
    val id: String? = null,
    val title: String? = null, val name: String? = null, val titolo: String? = null,
    @SerialName("attachment_name") val attachmentName: String? = null,
    val filename: String? = null,
    val type: String? = null, val tipo: String? = null,
    val description: String? = null, val descrizione: String? = null,
    val url: String? = null,
    @SerialName("file_url") val fileUrl: String? = null,
    @SerialName("pdf_url") val pdfUrl: String? = null,
    @SerialName("document_url") val documentUrl: String? = null,
    @SerialName("attachment_url") val attachmentUrl: String? = null,
    @SerialName("allegato_url") val allegatoUrl: String? = null,
    val link: String? = null,
) {
    fun toRelatedDocument() = RelatedDocument(
        id = id ?: UUID.randomUUID().toString(),
        title = firstNonBlank(title, name, titolo, attachmentName, filename) ?: "Allegato",
        type = firstNonBlank(type, tipo) ?: "PDF",
        description = firstNonBlank(description, descrizione) ?: "",
        url = firstNonBlank(url, fileUrl, pdfUrl, documentUrl, attachmentUrl, allegatoUrl, link),
    )
}
private fun firstNonBlank(vararg v: String?) = v.firstOrNull { !it.isNullOrBlank() }
```

> Use `@Serializable` with all-nullable fields + custom `toDomain()` mappers rather than custom `KSerializer`s. This reproduces the iOS "try each field, default gracefully" behaviour with far less code. kotlinx.serialization needs `ignoreUnknownKeys = true` and `isLenient = true`.

---

## 4. Image loading (Coil)

iOS `ImageCache` is a two-tier cache (NSCache memory: 100 items / 50 MB; FileManager disk), load order memory → disk → network. `RemoteImageView` shows the **official brand logo** (`dst_fallback_logo`, the cream-background "DITELO SUI TETTI" skyline + wordmark) whenever the URL is `null` **or** the download fails. There is **no random gradient** for editorial content. Fallback renders `scaledToFit` on a cream backing; thumbnails are 1:1.

Android with Coil:

```kotlin
@Composable
fun RemoteImage(
    url: String?,
    contentScale: ContentScale = ContentScale.Crop, // detail/featured = Crop; fallback uses Fit
    modifier: Modifier = Modifier,
) {
    val fallback = painterResource(R.drawable.dst_fallback_logo)
    AsyncImage(
        model = ImageRequest.Builder(LocalContext.current)
            .data(url)                       // null model → falls back automatically
            .crossfade(true)
            .build(),
        contentDescription = null,           // decorative; label the row, not the image
        placeholder = ColorPainter(BrandCream),
        error = fallback,
        fallback = fallback,                 // used when model is null (url == null)
        contentScale = contentScale,
        modifier = modifier.background(BrandCream),
    )
}
```

Configure the singleton `ImageLoader` so memory + disk caches match the intent of the iOS cache:

```kotlin
ImageLoader.Builder(context)
    .memoryCache { MemoryCache.Builder(context).maxSizePercent(0.20).build() }
    .diskCache {
        DiskCache.Builder()
            .directory(context.cacheDir.resolve("dst_image_cache"))
            .maxSizeBytes(50L * 1024 * 1024)   // mirror the 50 MB ceiling
            .build()
    }
    .build()
```

When the brand logo is shown as a fallback, set `contentScale = ContentScale.Fit` so the full mark is never cropped (iOS uses `scaledToFit` for exactly this reason). Keep the fallback asset `accessibilityHidden` equivalent (no contentDescription) — the surrounding row carries the label.

---

## 5. PDF behavior

iOS opens **both** document attachments and standalone documents in a PDFKit reader. `PDFDownloadService` (an `actor` — i.e. serialized access) downloads to a temp file, validates the response, caches by remote URL, and de-dupes in-flight downloads. Validation rules to replicate exactly:

1. Reject non-2xx status (`PDFDownloadError.httpError`).
2. Accept as PDF if the response **mime type contains "pdf"** OR the URL path extension is `.pdf`; otherwise reject as invalid content (`"Il file scaricato non è un PDF valido."`). This is how the 7 dead/HTML legacy document URLs are caught.
3. Always use the **resolved backend URL** (the document/attachment URL after the `.pdf`-preference resolution in §3) — never a hand-built path.

Android approach:

| Path | When | How |
|---|---|---|
| **Bundled `PdfRenderer`** (preferred, offline-capable) | URL resolves to a real `.pdf` | Download to `cacheDir` on `Dispatchers.IO`, validate Content-Type / extension exactly as above, render pages to bitmaps in a `LazyColumn`. |
| **Chrome Custom Tabs** (fallback) | quick view / share / when bundled render is overkill | `CustomTabsIntent` to the resolved URL. |
| **WebView** (fallback) | embedded page render needed | `WebView` pointed at a Google Docs viewer or the URL directly. |

```kotlin
sealed interface PdfResult { data class File(val file: java.io.File) : PdfResult; object NotAPdf : PdfResult; data class Http(val code: Int) : PdfResult }

suspend fun downloadPdf(remote: String): PdfResult = withContext(Dispatchers.IO) {
    val req = Request.Builder().url(remote).build()
    okHttp.newCall(req).execute().use { resp ->
        if (!resp.isSuccessful) return@withContext PdfResult.Http(resp.code)
        val mime = resp.header("Content-Type").orEmpty()
        val isPdf = mime.contains("pdf", true) || Uri.parse(remote).lastPathSegment?.endsWith(".pdf", true) == true
        if (!isPdf) return@withContext PdfResult.NotAPdf   // catches the 7 legacy HTML/404 docs
        val out = File(context.cacheDir, Uri.parse(remote).lastPathSegment ?: "${UUID.randomUUID()}.pdf")
        resp.body!!.byteStream().use { input -> out.outputStream().use { input.copyTo(it) } }
        PdfResult.File(out)
    }
}
```

On `NotAPdf` / `Http`, surface a friendly error and offer "Apri esternamente" (Custom Tabs) — exactly the iOS reader's escape hatch ("Apri esternamente" / Share). Cache by remote URL and de-dup concurrent requests (a `Mutex`-guarded map, mirroring the iOS in-flight task map).

---

## 6. Suggested Kotlin package / module structure

Single `:app` module is fine for v1; split later if needed. Folder layout mirrors the iOS modular layout (Design / Models / Components / Screens / Utilities / Services / Persistence).

```
com.ditelosuitetti.android
├── app/                 // Application, MainActivity, NavHost, Hilt modules
├── core/
│   ├── design/          // DT tokens: colors, spacing, typography, shapes
│   ├── ui/              // reusable composables (RemoteImage, EmptyState, SkeletonCard, CategoryChip)
│   └── util/            // EditorialSort, EditorialDates, date formatting, HTML text
├── data/
│   ├── network/         // Retrofit/Ktor service, ApiClient, retry, error mapping
│   ├── dto/             // ArticleDto, EventDto, DocumentDto, AttachmentDto, SyncResponseDto
│   ├── mapper/          // Dto -> domain, domain -> Room entity
│   ├── local/           // Room db, DAOs, entities, DataStore keys
│   └── repository/      // EditorialRepository (interface) + LiveEditorialRepository
├── domain/
│   └── model/           // Article, Event, Document, RelatedDocument
└── feature/
    ├── onboarding/      // 3 bokeh slides + NotificationPermission pre-prompt
    ├── home/            // hero, stats strip, "In evidenza" (first 6), events section
    ├── articles/        // filter bar + featured hero + list; detail with attachments
    ├── documents/       // list -> detail -> PdfReader
    ├── about/           // Chi siamo: mission, support CTA, privacy, rate, social, developer
    └── support/         // Sostieni: donation/IBAN sheet, notif settings, hidden diagnostics
```

### Navigation (4 tabs, each its own back stack)

iOS uses a `TabView` of 4 tabs, each a `NavigationStack`: **Home**, **Articoli**, **Documenti**, **Chi siamo**. (Per the project memory, "Per il Sì" and "Comitati" were intentionally dropped — do not add them.) Use a Compose `NavHost` per tab via nested navigation graphs, or Navigation3 / `BottomNavigation` with separate back stacks (e.g. one `NavHost` and a `BottomBar`, or per-tab graphs).

Deep links (`AppDeepLinkRouter`): `suitetti.org/{articoli|eventi|documenti}/{slug}` → register matching `<intent-filter>` deep links / `navDeepLink` patterns routing to article/event/document detail by `slug`.

### Threading

- UI state: `Dispatchers.Main` (default for `StateFlow` emission from `viewModelScope`).
- Network, Room, DataStore reads/writes, PDF download, image disk I/O: `Dispatchers.IO` via `withContext`.
- Never block the main thread on sync, decode, or file I/O — the iOS app keeps the main actor free for exactly this reason.

### Error / loading / empty state parity (Definition of Done)

Every screen must reproduce the three explicit states the iOS app has:

| State | iOS | Android |
|---|---|---|
| Loading | `SkeletonCard` / `SkeletonLoadingList`, `isLoading` | shimmer/skeleton composables driven by `state.isLoading` |
| Error | `errorMessage` surfaced; localized Italian strings | `state.errorMessage` → error composable + retry |
| Empty | `EmptyStateView` | dedicated empty composable when list is empty and not loading |
| Offline (stale cache) | `offlineMessage` banner, content still shown | banner string, do not clear cached content |

---

## 7. Design system tokens

Carry the DT token set over verbatim into a Compose theme. Values verified from the iOS Design layer and fact sheet:

| Token | Value | Compose |
|---|---|---|
| `brandCream` (background) | ≈ `#F5EFE6` warm cream | `Color(0xFFF5EFE6)` |
| `brandRed` (accent) | ≈ `#C0141E` | `Color(0xFFC0141E)` |
| `brandBlack` (text) | near-black | theme `onBackground` |
| `brandGray` / `brandGrayLight` | metadata text | muted greys |
| `brandSep` | separators | divider color |
| `cornerRadius` | 22 | large shape |
| `smallCorner` | 14 | small shape |
| `padding` | 16 | base spacing |
| `sectionSpacing` | 12 | between sections |
| `readableMaxWidth` | 820 | cap detail/list width on tablets (`horizontalSizeClass == .regular` ⇒ use `WindowSizeClass`/`BoxWithConstraints` ≥ 600dp) |
| `topBarContentOffset` | 62 | top inset |

Liquid Glass surfaces (translucent white at ~0.82 opacity, ultra-thin/thin material, subtle shadows, rounded floating controls, floating tab bar) → approximate with translucent `Surface`/`Card` (`color.copy(alpha = 0.82f)`), elevation/shadow, and `RenderEffect.createBlurEffect` (API 31+) where a frosted look is needed; keep main article body text on a **solid** background for legibility. Typography: large editorial serified/system fonts, bold/black weights, negative letter-spacing, italic accents; support Dynamic Type via `sp` + respecting font scale.

**iPad split → tablet two-pane:** iOS Articoli uses a `GeometryReader` HStack split on regular width (list left ~40%, clamped 280–400 pt; detail right) with an `onSelect` closure; iPhone uses push navigation with a zoom transition. On Android, branch on `WindowSizeClass`: compact = list → detail navigation; expanded = `Row` with a list pane (clamp ~280–400dp) + detail pane.

Components to port (reusable, 1:1 with iOS): `CategoryChip`, `ArticleListRow`, `FeaturedArticleCard`/`ArticlesFeaturedCard`, `LinkedDocumentCard` (premium PDF card), `DocumentListRow`, `EventInfoCard`, `EventRow`, `DetailHeroImage`, `DetailTitleCard`, `RemoteImage`, `EmptyStateView`, `SkeletonCard`/`SkeletonLoadingList`, PDF viewer, `TickerView`.

---

## 8. Accessibility parity

- VoiceOver labels on all rows → Compose `Modifier.semantics { contentDescription = ... }` / `mergeDescendants`. iOS combines or ignores children per row; on Android merge row semantics so the whole row is one node.
- The premium PDF card label is `"Apri documento PDF, [title]"` — reproduce verbatim as the card's content description.
- Minimum tap target **44×44 pt** on iOS → **48dp** on Android (`Modifier.minimumInteractiveComponentSize()` / `sizeIn(minWidth = 48.dp, minHeight = 48.dp)`).
- Dynamic Type → honor system font scale (`sp` units, no fixed `dp` text).
- Reduce Motion guards on animations → check `Settings.Global.ANIMATOR_DURATION_SCALE` / provide reduced-motion variants; the onboarding bokeh and hero animations especially.
- Sufficient contrast (metadata uses `brandGray`); keep body text on solid backgrounds.

---

## 9. Conversion checklist / phased plan

### Phase 0 — Project setup
- [ ] Create the Android project (Kotlin, Compose, min SDK reasonable for `PdfRenderer` and blur where used).
- [ ] Add Hilt, Retrofit/OkHttp **or** Ktor, kotlinx.serialization (`ignoreUnknownKeys`, `isLenient`), Room, DataStore, Coil, Navigation, `kotlinx-datetime`/`java.time`.
- [ ] `BuildConfig` base URL (`https://kbswgeliohnpwopzzzpc.supabase.co`) + endpoint builders; `User-Agent: DiteloSuiTetti-Android/1.0`.
- [ ] Add `dst_fallback_logo` to `res/drawable` (export the cream-background brand mark from `Assets.xcassets`).

### Phase 1 — Data layer (highest-risk, do first)
- [ ] DTOs with all-nullable fields + aliases per §3; `SyncResponseDto`.
- [ ] Per-item lossy decoding helper (§2) — write a unit test that a single malformed row drops without emptying the section.
- [ ] Multi-format date parsing (`EditorialDates`) + unit tests for fractional ISO8601, plain ISO8601, and `yyyy-MM-dd`-as-UTC.
- [ ] `ApiClient` with 20s timeout + retry (2 retries, 0.5s/1.0s, retryable = offline/timeout/transport/5xx only) + typed error mapping (offline / timeout / bad status / decode).
- [ ] Domain mappers, including document `.pdf`-preference URL resolution and attachment alias resolution.
- [ ] `EditorialSort` (newest-first, undated last, stable) + tests.
- [ ] Room entities/DAOs + DataStore keys; schema version = 2 with one-time purge that only advances after a confirmed clear.
- [ ] `EditorialRepository`: cache-first load → background sync → clear-and-replace in one transaction → stamp `lastSuccessfulSyncDate`; offline → keep cache + warning.

### Phase 2 — State & shell
- [ ] Three ViewModels (`Articles`, `Events`, `Documents`) with `StateFlow<UiState>` and the single sort choke-point; load-once-when-empty + refresh.
- [ ] Hilt graph wiring repository/db/datastore/imageLoader.
- [ ] 4-tab scaffold (Home / Articoli / Documenti / Chi siamo), per-tab back stacks, deep-link intent filters for `suitetti.org/{articoli|eventi|documenti}/{slug}`.
- [ ] Onboarding gate (DataStore `hasSeenOnboarding`) → optional notification pre-prompt.

### Phase 3 — UI
- [ ] Design tokens + theme (colors, shapes, spacing, typography, dynamic type).
- [ ] `RemoteImage` + Coil loader (50 MB disk, ~20% memory, brand-logo error/fallback, Fit for fallback).
- [ ] Reusable components (§7). Loading/error/empty composables wired to UI state.
- [ ] Home (hero + stats strip + first-6 featured + events), Articoli (filter bar outside scroll + featured + list, tablet two-pane), Article/Event detail (hero, title card, body, attachments; event info card + Maps tap + add-to-calendar via `Intent`).
- [ ] Documenti list → detail → PDF reader.

### Phase 4 — PDF & integrations
- [ ] `PdfRenderer` viewer + download/validate service (§5) with mime/extension check and in-flight de-dup; Custom Tabs / WebView fallback + "Apri esternamente" / Share.
- [ ] Calendar add (iOS EventKit → Android `Intent(Intent.ACTION_INSERT, CalendarContract.Events.CONTENT_URI)`).
- [ ] Maps tap (`geo:` / Google Maps intent), social links, IBAN copy, rate-app (Play In-App Review), privacy policy.

### Phase 5 — Hardening & DoD
- [ ] Accessibility pass (§8): row semantics, 48dp targets, dynamic type, reduce-motion.
- [ ] Verify the 7 known-bad document URLs fail gracefully (NotAPdf → friendly error + external open), not a crash.
- [ ] Confirm parity of loading/error/empty/offline states on every screen.
- [ ] Optional: wire `?since=` delta sync and push notifications once the backend re-host and APNs/FCM parity are settled.

### Known backend caveats to carry into Android QA
- ~123/273 articles have **null** `immagine_url` → fallback logo must look intentional everywhere.
- 7/25 documents have dead/HTML legacy `www.suitetti.org` URLs (re-host pending) → reader must degrade gracefully.
- `data_evento` can be empty and `ora` is frequently null → events must still render (undated / no time), never drop.
- `server_time` may be absent → default to "now".

---

### Source-of-truth files (iOS) for any field-level question
- Sync orchestration: `DiteloSuiTetti/Services/Sync/EditorialSyncCoordinator.swift`
- Networking + decoder + retry: `DiteloSuiTetti/Network/APIClient.swift`
- Response + lossy wrapper: `DiteloSuiTetti/Models/EditorialSyncResponseDTO.swift`
- DTOs: `DiteloSuiTetti/Models/{ArticleDTO,EventDTO,DocumentDTO,AttachmentDTO}.swift`
- Sort: `DiteloSuiTetti/Utilities/EditorialSort.swift`
- Offline cache: `DiteloSuiTetti/Persistence/EditorialCacheRepository.swift` (+ `Cached*`)
- Image cache + fallback: `DiteloSuiTetti/Utilities/ImageCache.swift`, `DiteloSuiTetti/Components/Common/RemoteImageView.swift`
- PDF: `DiteloSuiTetti/Services/PDF/PDFDownloadService.swift`, `DiteloSuiTetti/Components/PDF/PDFKitView.swift`
- Env/endpoints: `DiteloSuiTetti/Configuration/AppEnvironment.swift`
- Store pattern: `DiteloSuiTetti/Stores/{Article,Event,Document}Store.swift`

Companion docs in `docs/`: `API_CONTRACT.md`, `ANDROID_HANDOFF.md`, `ANDROID_IMPLEMENTATION_PLAN.md`.

---

## Addendum — Sharing & support (2026-06-09)

**Canonical share domain: `https://www.suitetti.org`.** Share the same canonical URLs on Android — never legacy/preview domains (`comitaticivici.it`, `*.lovable.app`):
- Article → `https://www.suitetti.org/articoli/{slug}`
- Event   → `https://www.suitetti.org/eventi/{slug-or-id}`
- Document→ `https://www.suitetti.org/documenti/{slug}`

**Share content is an invitation, not a bare URL** — build a message with the title + canonical URL + the store link:

```kotlin
fun articleShareText(title: String, slug: String) = """
    Ti invito a leggere questo articolo su Ditelo sui Tetti:

    $title

    Aprilo sul sito o scarica l'app per seguire articoli, eventi e documenti:
    https://www.suitetti.org/articoli/$slug

    App Android:
    https://play.google.com/store/apps/details?id=<your.package>
""".trimIndent()
// share via Intent.ACTION_SEND (text/plain) wrapped in Intent.createChooser
```
(iOS appends the App Store listing `https://apps.apple.com/it/app/suitetti/id6772963310`; swap the Play Store URL on Android.)

**Home promo banner** (updated 2026-07-02): now an active **Festival spotlight** that opens the Festival page in the **external browser** — see the "Evergreen hero + Festival spotlight" addendum below.

**Technical support**: the About screen has a "Supporto tecnico" card → email **info@digitalyogin.com**, subject `Supporto Ditelo sui Tetti iOS v{version} ({build})` (Android: `… Android v{versionName} ({versionCode})`) + pre-filled Italian body. Use `ACTION_SENDTO` `mailto:`; if nothing resolves, show a dialog with the address. Percent-encode subject/body.

---

## Addendum — Evergreen hero + Festival spotlight (2026-07-02)

The website published post-festival videos + extra material. The app was made evergreen while surfacing the 3° Festival via an in-app web view. Mirror on Android:

**Hero stats are evergreen.** The Home hero strip (`HeroStatsView`) shows `100+ Associazioni · 312 Comitati · Italia / Rete civica` — all static, none date-bound. Do **not** hardcode a date/edition stat (the old `16 giu · 3° Festival` went stale). The dead `HomeStatsStrip` was removed.

**Festival spotlight card → external browser.** A reusable dark promo card (`HomePromoCard`: eyebrow chip + title + arrow; whole card is one ≥48dp button with a merged content description) sits under the events section. Tapping opens the Festival page in the **external browser** (iOS: SwiftUI `openURL`):

- **Android**: open the URL externally with `Intent(Intent.ACTION_VIEW, uri)` (default browser) — mirror the iOS "open in Safari" behavior. Do **not** use a `WebView` / Custom Tab for this card; the festival page is rich web content that reads best full-screen in the browser.
- The destination is `AppEnvironment.festivalURL` on iOS = `https://www.suitetti.org/progetti/festival-umano-tutto-intero` (verified live: the festival hub with videos, gallery, and program/press downloads). It is a **website destination, not part of the sync payload.**
- Keep the component generic (copy + URL are the only time-bound values) so it can be repurposed for a future campaign.

**Onboarding slide 2** is evergreen: `IL FESTIVAL` / `SUI TETTI / FESTIVAL` / "Ci vediamo sui tetti." (dropped `3°`, `2026`, and the future-tense "Ti aspettiamo").

**Option B (native Festival/Project detail) is backend-gated.** A festival is already a normal event (`tipo: "Festival"`) with the full native event detail (cover, description, external link, PDF attachments). A dedicated native detail with a **video player** + **related articles** needs new API fields (`video_url` or typed `video` attachments; `related_article_ids` or a shared `project_id`) — see `API_CONTRACT.md` → "Proposed: Festival / Project content". Build the same on Android once those fields ship.
