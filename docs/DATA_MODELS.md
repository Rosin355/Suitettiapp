# Data Models — Ditelo sui Tetti

> Living document for the Android / Jetpack Compose conversion. Mirrors the verified iOS codebase (2026-06-09). When the iOS DTOs change, update this file first.

This is the canonical reference for the editorial data layer. It describes the wire format (the public Supabase sync endpoint), the iOS DTOs that decode it, the resilient-decode rules that keep one bad record from emptying a section, the UI-model vs DTO distinction, and ready-to-paste Kotlin `@Serializable` DTOs plus Room `@Entity` sketches for the offline cache.

---

## 1. Transport overview

| Item | Value |
|---|---|
| Endpoint (full sync) | `https://kbswgeliohnpwopzzzpc.supabase.co/functions/v1/sync-editorial` |
| Endpoint (delta sync) | `…/sync-editorial?since=<ISO8601>` (e.g. `2026-05-19T00:00:00Z`) |
| Method | `GET` |
| Auth | None — public |
| Top-level JSON keys | `server_time`, `articles[]`, `events[]`, `documents[]` |
| Live counts | 273 articles, ~63 events, 25 documents |

The response is wrapped by `EditorialSyncResponseDTO`. `server_time` defaults to "now" if missing/invalid; each of `articles`, `events`, `documents` defaults to an empty array if the key is missing or the wrong type. Within each array, **per-item lossy decoding** is applied (see §5).

### Date decoding strategy (applies to every `Date` field)

The iOS `JSONDecoder` uses `keyDecodingStrategy = .convertFromSnakeCase` and a custom date strategy that tries, in order:

1. ISO8601 with fractional seconds (`.withInternetDateTime, .withFractionalSeconds`)
2. plain ISO8601 (`.withInternetDateTime`)
3. date-only `yyyy-MM-dd` parsed in **UTC** with `en_US_POSIX` locale

If none match, the decode of that single field throws (and is tolerated as `nil` where the field uses `try?`).

On Android replicate this with a custom `KSerializer<Instant>` / `KSerializer<LocalDate>` that attempts the same three formats. Note: `data_evento` is always date-only (`yyyy-MM-dd`); the rest are timestamps.

---

## 2. Article

JSON keys are snake_case on the wire; the decoder converts to camelCase. Attachments arrive under `attachments` **or** the alias `allegati`.

| JSON field (snake_case) | Swift type | Nullable | Kotlin type | Notes |
|---|---|---|---|---|
| `id` | `UUID` | No | `String` (UUID) | Hard-required. Identity. |
| `titolo` | `String` | No | `String` | Hard-required. Title. |
| `slug` | `String` | No | `String` | Required on iOS; used for deep links. |
| `categoria` | `String` | No | `String` | Category label. |
| `data_pubblicazione` | `Date?` | Yes | `Instant?` | Sort key. ISO date; ~missing tolerated. |
| `estratto` | `String` | No | `String` | Excerpt. |
| `contenuto` | `String` | No | `String` | Body, may contain HTML. |
| `immagine_url` | `String?` | Yes | `String?` | **~123 of 273 are null.** Null/failed → brand-logo fallback. |
| `updated_at` | `Date?` | Yes | `Instant?` | Sync bookkeeping. |
| `sync_version` | `Int` | No | `Int` | Required on iOS. |
| `attachments` / `allegati` | `[RelatedDocument]` | array (defaults `[]`) | `List<AttachmentDto>` | Per-item lossy. Either key accepted. |

Hard-required on iOS: `id`, `titolo`, `slug`, `categoria`, `estratto`, `contenuto`, `sync_version`. If any of those is missing/wrong-type, the whole article item fails and is dropped (the rest of the section survives). `data_pubblicazione` and `updated_at` are decoded with `try?` → `nil` on failure, with a diagnostic log.

For Android resilience, treat only `id` + `titolo` as truly mandatory and default the others, to avoid dropping otherwise-displayable articles.

---

## 3. Event

Attachments arrive under `attachments` or `allegati`. Events are the most defensively decoded type: **only `id` and `titolo` are hard-required.**

| JSON field (snake_case) | Swift type | Nullable | Kotlin type | Notes |
|---|---|---|---|---|
| `id` | `UUID` | No | `String` (UUID) | Hard-required. |
| `titolo` | `String` | No | `String` | Hard-required. |
| `slug` | `String` | No (defaults to `id`) | `String?` | Missing → falls back to id string. |
| `tipo` | `String` | No (defaults `""`) | `String?` | Tolerates null/missing. |
| `data_evento` | `String` | No (defaults `""`) | `String?` | **Date-only `YYYY-MM-DD`** string, kept raw. Empty → rendered "undated", never dropped. |
| `ora` | `String?` | Yes | `String?` | **Null is common** — must not drop the event. |
| `luogo` | `String` | No (defaults `""`) | `String?` | Location; tolerates null. |
| `descrizione` | `String` | No (defaults `""`) | `String?` | Tolerates null. |
| `link` | `String?` | Yes | `String?` | External link. |
| `immagine_url` | `String?` | Yes | `String?` | Null → brand-logo fallback. |
| `updated_at` | `Date?` | Yes | `Instant?` | |
| `sync_version` | `Int` | No (defaults `0`) | `Int?` | Tolerates null/missing. |
| `is_featured` | `Bool` | No (defaults `false`) | `Boolean` | **Home featured banner.** Missing key, null, or wrong type all decode to `false`. |
| `attachments` / `allegati` | `[RelatedDocument]` | array (defaults `[]`) | `List<AttachmentDto>` | Per-item lossy. |

Resilient-decode rule (verbatim intent): a malformed event must never drop from the list unless its identity (`id`) or `titolo` is missing. Every other field tolerates null/missing/wrong-type by falling back to a safe default. `data_evento` is kept as the **raw string** in the DTO and parsed when building the UI `Event`; an empty `data_evento` becomes an "undated" event rather than being discarded.

### 3.1 `is_featured` — the dynamic Home banner

Added 2026-08-12. Backed by the `events.is_featured` column and exposed through the
`mobile_events_public` view. It is the **single source of truth** for the featured-event
banner on the mobile home:

```
CMS "in evidenza" toggle → events.is_featured → mobile_events_public
    → sync-editorial → isFeatured → Home featured-event card → native Event Detail
```

Rules that both platforms must follow:

- The banner is **derived**, never stored. Resolve it from the current event list on every
  read; do not persist a separate "featured banner" record or a flag in
  DataStore/UserDefaults. Clearing the flag backend-side must make the banner vanish after
  the next successful sync, with no client-side business logic deciding otherwise.
- The flag is **independent of the date**. A featured past event still shows; the backend
  decides what is promoted, not the client.
- Do **not** confuse this with `is_mobile_visible`, which decides whether an event is
  delivered to the apps at all. They are different columns with different meanings.
- If more than one event is flagged (possible only via direct DB edits — the admin toggle
  is exclusive), pick a deterministic winner and log a warning rather than crashing or
  flickering. Order: upcoming first → nearest event date → newest `updated_at` → lowest
  `id`. The final `id` tiebreak is what guarantees the same winner across launches.
- `is_featured` must participate in the **cache-invalidation signature**. Toggling it often
  changes nothing else about the event, so a signature built only from text would keep a
  stale `is_featured = true` row and flash the banner on next launch.

---

## 4. Document

Documents resolve to a **single `url`** in the UI model, but the DTO accepts many candidate URL field names and prefers a direct `.pdf` URL.

| JSON field (snake_case) | Swift type | Nullable | Kotlin type | Notes |
|---|---|---|---|---|
| `id` | `UUID` | No | `String` (UUID) | **Only truly required field.** |
| `slug` | `String` | No (defaults to `id`) | `String?` | Missing → id string. |
| `titolo` (alias `title`) | `String` | No (defaults `"Documento"`) | `String?` | Italian first, then English, then placeholder. |
| `tipo` (alias `type`) | `String` | No (defaults `""`) | `String?` | |
| `categoria` (alias `category`) | `String` | No (defaults `""`) | `String?` | |
| `descrizione` (alias `description`) | `String` | No (defaults `""`) | `String?` | |
| `url` (+ aliases) | `String?` | Yes | `String?` | See URL resolution below. |
| `data_caricamento` (alias `created_at`) | `Date?` | Yes | `Instant?` | Sort key. |
| `updated_at` | `Date?` | Yes | `Instant?` | |
| `sync_version` | `Int` | No (defaults `0`) | `Int?` | |

### Document URL resolution

The DTO collects every known URL field, then **prefers a direct-PDF URL over an HTML page URL**. Candidate fields, in priority order, are: `url`, `file_url`, `pdf_url`, `document_url`, `attachment_url`, `public_url`, `legacy_url`, `link`. (Currently the backend only sends `url`; the others are forward-compat.) Resolution:

1. Collect all non-empty candidates.
2. Choose the first whose path extension is `pdf`.
3. Otherwise choose the first candidate.

URL audit (25 docs): 18 resolve to working Supabase storage (`…supabase.co/storage/v1/object/public/document-files/…`); 7 carry legacy `www.suitetti.org` URLs that are dead (404) or HTML pages — backend re-host pending. A document whose chosen URL is not PDF-like is logged via `[DocumentURL]`.

On Android, replicate the "prefer .pdf" picker, then route a `.pdf` to `PdfRenderer`/WebView and a non-PDF page URL to Chrome Custom Tabs.

---

## 5. Attachment / RelatedDocument

`AttachmentDTO` is the flexible wire decoder; it maps to `RelatedDocument`, the UI/cache model used inside articles and events. Attachments do **not** carry a date or file size.

`AttachmentDTO` accepts these field-name variants (first non-empty wins):

| Logical field | Accepted JSON keys (snake_case on the wire) | Default |
|---|---|---|
| id | `id` | new random UUID if missing |
| title | `title`, `name`, `titolo`, `attachment_name`, `filename` | `"Allegato"` |
| type | `type`, `tipo` | `""` → becomes `"PDF"` in `RelatedDocument` |
| description | `description`, `descrizione` | `""` |
| url | `url`, `file_url`, `pdf_url`, `document_url`, `attachment_url`, `allegato_url`, `link` | `nil` |

`RelatedDocument` (the resolved model) fields:

| Field | Swift type | Nullable | Kotlin type | Notes |
|---|---|---|---|---|
| `id` | `UUID` | No | `String` (UUID) | |
| `title` | `String` | No | `String` | |
| `type` | `String` | No | `String` | `""` → `"PDF"` at mapping time. |
| `description` | `String` | No | `String` | |
| `url` | `URL?` | Yes | `String?` | Parsed from the chosen string. |

Note: the `AttachmentDTO` decoder never throws — every field falls back gracefully — so the parent `[Lossy<AttachmentDTO>]` array decode is robust. A bad attachment is simply dropped from the list.

### Lossy per-item wrapper

`articles`, `events`, `documents`, and each attachments array are decoded as `[Lossy<T>]`. `Lossy<T>` attempts `T(from:)`; on failure it stores `nil` plus the error instead of throwing. The section then `compactMap`s to the successful items. Result: one malformed record never empties a whole section. Kotlin equivalent: decode element-by-element in a custom array deserializer (or `JsonArray` + `decodeFromJsonElement` in a try/catch per element), collecting successes.

---

## 6. UI model vs DTO distinction

DTOs mirror the wire format. The UI models add presentation-only fields and parsed/derived values. Mappers (`ArticleMapper`, `EventMapper`, `DocumentMapper`) bridge DTO → UI model.

Key derived/added fields:

- **`publishedAt: Date?`** added to `Article` and `Document` purely for sorting. Display never uses it directly — it drives `EditorialSort` (newest-first; undated items last, stable by original index). It is sourced from `data_pubblicazione` (article) / `data_caricamento` (document).
- **Formatted date strings for display.** `Article` carries `date` (short) and `fullDate` (e.g. "7 giugno 2026"). `Document` carries `uploadedAt` (display string). `Event` carries `day` ("07"), `monthShort` ("GIU"), `fullDate` ("7 giugno 2026"), and `time` ("10:00" or "").
- **`Event.rawDate: Date?`** parsed from the raw `data_evento` string; powers `isUpcoming` / `isPast` / `isUndated` and the EventKit "add to calendar" flow.
- **Presentation-only color tokens** on `Article`: `categoryColor` and `thumbnailColors` are derived locally from a palette indexed by the id — they are NOT from the backend and should be recomputed on Android, not persisted.
- **`imageURL: URL?` / `url: URL?` / `link: URL?`** are parsed from their string forms; nil-or-unparseable falls back to the brand logo (images) or a disabled state (PDF links).

`Article` (UI model) fields: `id`, `slug`, `category`, `categoryColor`*, `thumbnailColors`*, `title`, `date`*, `fullDate`*, `publishedAt`, `readTime`*, `excerpt`, `body`, `imageURL`, `relatedDocuments`. (* = derived/display-only.)

`Event` (UI model) fields: `id`, `title`, `slug`, `type`, `day`*, `monthShort`*, `fullDate`*, `time`, `location`, `description`, `link`, `imageURL`, `rawDate`, `updatedAt`, `syncVersion`, `isFeatured`, `relatedDocuments`.

`Document` (UI model) fields: `id`, `title`, `slug`, `type`, `category`, `description`, `url`, `uploadedAt`*, `publishedAt`, `updatedAt`, `syncVersion`.

For Android, keep this split: kotlinx.serialization DTOs for the wire, plain UI/domain models for Compose, and a mapper layer that parses dates, derives display strings, picks the document URL, and recomputes palette colors.

---

## 7. Kotlin DTOs (kotlinx.serialization, ready to paste)

These mirror the iOS decoders. They assume custom serializers `InstantFlexibleSerializer` (the three-format date strategy) for timestamps; `data_evento` is kept as a raw `String`. Use `@SerialName` for snake_case keys and `@JsonNames` (experimental) for aliases; where multiple URL aliases must be tried-in-order with PDF preference, do that in the mapper, not the serializer.

```kotlin
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonNames
import kotlinx.datetime.Instant

@Serializable
data class EditorialSyncResponseDto(
    @SerialName("server_time") @Serializable(InstantFlexibleSerializer::class)
    val serverTime: Instant? = null,
    val articles: List<ArticleDto> = emptyList(),
    val events: List<EventDto> = emptyList(),
    val documents: List<DocumentDto> = emptyList(),
)

@Serializable
data class ArticleDto(
    val id: String,                                   // UUID; hard-required
    val titolo: String,                               // hard-required
    val slug: String = "",
    val categoria: String = "",
    @SerialName("data_pubblicazione") @Serializable(InstantFlexibleSerializer::class)
    val dataPubblicazione: Instant? = null,           // sort key
    val estratto: String = "",
    val contenuto: String = "",                       // may contain HTML
    @SerialName("immagine_url")
    val immagineUrl: String? = null,                  // ~123/273 null
    @SerialName("updated_at") @Serializable(InstantFlexibleSerializer::class)
    val updatedAt: Instant? = null,
    @SerialName("sync_version")
    val syncVersion: Int = 0,
    // Either "attachments" or "allegati" on the wire.
    @JsonNames("attachments", "allegati")
    val attachments: List<AttachmentDto> = emptyList(),
)

@Serializable
data class EventDto(
    val id: String,                                   // UUID; hard-required
    val titolo: String,                               // hard-required
    val slug: String? = null,                         // null → fall back to id in mapper
    val tipo: String? = null,
    @SerialName("data_evento")
    val dataEvento: String? = null,                   // raw "YYYY-MM-DD"
    val ora: String? = null,                          // commonly null
    val luogo: String? = null,
    val descrizione: String? = null,
    val link: String? = null,
    @SerialName("immagine_url")
    val immagineUrl: String? = null,
    @SerialName("updated_at") @Serializable(InstantFlexibleSerializer::class)
    val updatedAt: Instant? = null,
    @SerialName("sync_version")
    val syncVersion: Int? = null,
    @JsonNames("attachments", "allegati")
    val attachments: List<AttachmentDto> = emptyList(),
)

@Serializable
data class DocumentDto(
    val id: String,                                   // UUID; only truly required field
    val slug: String? = null,
    @JsonNames("titolo", "title")
    val titolo: String? = null,                       // null → "Documento" in mapper
    @JsonNames("tipo", "type")
    val tipo: String? = null,
    @JsonNames("categoria", "category")
    val categoria: String? = null,
    @JsonNames("descrizione", "description")
    val descrizione: String? = null,
    // Candidate URL fields — mapper picks .pdf-first, then first non-empty.
    val url: String? = null,
    @SerialName("file_url")       val fileUrl: String? = null,
    @SerialName("pdf_url")        val pdfUrl: String? = null,
    @SerialName("document_url")   val documentUrl: String? = null,
    @SerialName("attachment_url") val attachmentUrl: String? = null,
    @SerialName("public_url")     val publicUrl: String? = null,
    @SerialName("legacy_url")     val legacyUrl: String? = null,
    val link: String? = null,
    @SerialName("data_caricamento") @JsonNames("data_caricamento", "created_at")
    @Serializable(InstantFlexibleSerializer::class)
    val dataCaricamento: Instant? = null,             // sort key
    @SerialName("updated_at") @Serializable(InstantFlexibleSerializer::class)
    val updatedAt: Instant? = null,
    @SerialName("sync_version")
    val syncVersion: Int? = null,
) {
    /** Prefer a direct .pdf URL over an HTML page URL; else first non-empty. */
    fun resolvedUrl(): String? {
        val candidates = listOfNotNull(
            url, fileUrl, pdfUrl, documentUrl,
            attachmentUrl, publicUrl, legacyUrl, link,
        ).filter { it.isNotBlank() }
        return candidates.firstOrNull { it.substringBefore('?').endsWith(".pdf", true) }
            ?: candidates.firstOrNull()
    }
}

@Serializable
data class AttachmentDto(
    val id: String? = null,                           // null → generate UUID in mapper
    @JsonNames("title", "name", "titolo", "attachment_name", "filename")
    val title: String? = null,                        // null → "Allegato"
    @JsonNames("type", "tipo")
    val type: String? = null,                         // blank → "PDF"
    @JsonNames("description", "descrizione")
    val description: String? = null,
    @JsonNames("url", "file_url", "pdf_url", "document_url",
               "attachment_url", "allegato_url", "link")
    val url: String? = null,
)
```

Notes:
- `@JsonNames` requires `Json { coerceInputValues = true }` is not enough on its own — enable it via the experimental serialization API; if you prefer stability, write a small custom deserializer that reads a `JsonObject` and tries the alias keys in order (this also lets you replicate the exact "first non-empty wins" semantics).
- Configure `Json { ignoreUnknownKeys = true; isLenient = true }`.
- Per-item lossy decoding is NOT expressible with plain `@Serializable` lists — decode each section as `JsonArray` and `decodeFromJsonElement<…>` per element inside try/catch, dropping failures (mirroring `Lossy<T>`).
- Domain mapping: `AttachmentDto` → `RelatedDocument(id = id ?: randomUuid, title ?: "Allegato", type.ifBlank { "PDF" }, description ?: "", url)`.

---

## 8. Room entities (offline cache sketch)

The iOS app caches via SwiftData (`CachedArticle`, `CachedEvent`, `CachedDocument`) with `id` as the unique key, stores URLs as strings, and serializes `relatedDocuments` to a JSON string. Cache schema version is **2**; bumping the version triggers a one-time stale-cache purge. Mirror this on Android with Room + a version constant in DataStore.

`CachedEvent.isFeatured` (2026-08-12) was added **without** a version bump: it carries a
default value, so SwiftData migrates existing stores automatically and users keep their
offline content. Old rows read back as `false`, which is the correct pre-sync state. On
Android, do the same with a Room migration that adds the column `NOT NULL DEFAULT 0`
rather than a destructive migration.

```kotlin
import androidx.room.Entity
import androidx.room.PrimaryKey

// Display-only color tokens are NOT cached — recompute from id at read time.

@Entity(tableName = "cached_articles")
data class CachedArticleEntity(
    @PrimaryKey val id: String,            // UUID
    val slug: String,
    val category: String,
    val title: String,
    val date: String,                      // display short date
    val fullDate: String,                  // display "7 giugno 2026"
    val publishedAt: Long?,                // epoch millis; sort key
    val readTime: String,
    val excerpt: String,
    val body: String,
    val imageUrl: String?,                 // null → brand-logo fallback
    val relatedDocumentsJson: String?,     // JSON-encoded List<RelatedDocument>, null if empty
)

@Entity(tableName = "cached_events")
data class CachedEventEntity(
    @PrimaryKey val id: String,            // UUID
    val title: String,
    val slug: String,
    val type: String,
    val day: String,                       // "07"
    val monthShort: String,                // "GIU"
    val fullDate: String,                  // "7 giugno 2026"
    val time: String,                      // "10:00" or ""
    val location: String,
    val eventDescription: String,          // "description" is reserved-ish; keep prefixed
    val link: String?,
    val imageUrl: String?,
    val rawDate: Long?,                     // epoch millis of parsed start date
    val updatedAt: Long?,
    val syncVersion: Int,
    val isFeatured: Boolean = false,        // Home featured banner; default keeps old rows migratable
    val relatedDocumentsJson: String?,
)

@Entity(tableName = "cached_documents")
data class CachedDocumentEntity(
    @PrimaryKey val id: String,            // UUID
    val title: String,
    val slug: String,
    val type: String,
    val category: String,
    val documentDescription: String,
    val url: String?,                      // resolved (pdf-preferred) URL string
    val uploadedAt: String,                // display string
    val publishedAt: Long?,                // epoch millis; sort key
    val updatedAt: Long?,
    val syncVersion: Int,
)
```

Caching guidance for Android:
- Persist the resolved/derived UI values (formatted date strings, picked PDF URL), not the raw DTO — exactly as iOS caches the UI model.
- Store `RelatedDocument` lists as a JSON string column (matching `relatedDocumentsJSON` on iOS). A `RelatedDocument` is `{ id, title, type, description, url }`.
- Do NOT persist `Article.categoryColor` / `thumbnailColors`; recompute deterministically from `id` on read.
- Cold launch: read cache first, render, then background-sync and replace. Keep a `cacheSchemaVersion` in DataStore; on bump, purge all three tables once.
- Ordering: apply newest-first by `publishedAt` (articles/documents) and by `rawDate` (events), undated last, stable by insertion order — mirror `EditorialSort`.

---

## 9. Cross-platform field-name quick reference

| Concept | Article | Event | Document |
|---|---|---|---|
| Identity | `id` | `id` | `id` |
| Title | `titolo` | `titolo` | `titolo` / `title` |
| Slug | `slug` | `slug` | `slug` |
| Type/Category | `categoria` | `tipo` | `tipo`/`type`, `categoria`/`category` |
| Sort date (JSON) | `data_pubblicazione` | `data_evento` (raw `YYYY-MM-DD`) | `data_caricamento` / `created_at` |
| Image | `immagine_url` | `immagine_url` | — |
| Doc URL | — | — | `url` (+ aliases, pdf-preferred) |
| External link | — | `link` | — |
| Body/desc | `contenuto`, `estratto` | `descrizione` | `descrizione` / `description` |
| Time/place | — | `ora`, `luogo` | — |
| Attachments | `attachments` / `allegati` | `attachments` / `allegati` | — |
| Bookkeeping | `updated_at`, `sync_version` | `updated_at`, `sync_version` | `updated_at`, `sync_version` |
| Hard-required | `id` + `titolo` (Android floor) | **`id` + `titolo` only** | **`id` only** |
