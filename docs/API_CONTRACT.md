# API Contract — Ditelo sui Tetti

Documents the Supabase Edge Function API consumed by the iOS app. Android must implement the same contract.

---

## Base URL

```
https://kbswgeliohnpwopzzzpc.supabase.co
```

No authentication headers are required for the editorial sync endpoint. It is a public, read-only API.

---

## Endpoints

### Full Sync

```
GET /functions/v1/sync-editorial
```

Returns the full dataset of articles, events, and documents.

### Delta Sync

```
GET /functions/v1/sync-editorial?since=2026-05-19T00:00:00Z
```

Returns only items updated after the given ISO 8601 timestamp. The iOS app currently always performs a full sync; the delta endpoint is available for future use. The `since` parameter should be the `serverTime` from the previous successful response.

### Push Token Registration

```
POST /functions/v1/register-push-token
Content-Type: application/json
```

Request body:
```json
{
  "deviceToken": "<hex-string (iOS) or FCM token (Android)>",
  "platform": "ios",
  "environment": "sandbox | production",
  "bundleId": "com.example.app",
  "appVersion": "1.7.0",
  "buildNumber": "42"
}
```

Response (success):
```json
{ "ok": true }
```

Response (error):
```json
{ "error": "<message>" }
```

**Android notes**:
- Set `"platform": "android"` instead of `"ios"`.
- There is no `"sandbox"` concept in FCM; always send `"environment": "production"`.
- The token is an FCM registration token, not an APNs hex string.
- Register (or re-register) the token whenever `FirebaseMessaging.getInstance().token` changes.
- Skip registration if the current token matches the last successfully registered token (store in SharedPreferences).

---

## Editorial Sync Response Shape

```json
{
  "serverTime": "2026-05-28T10:30:00.000Z",
  "articles": [ ...ArticleDTO ],
  "events":   [ ...EventDTO   ],
  "documents": [ ...DocumentDTO ]
}
```

`serverTime` is ISO 8601 with fractional seconds. Store it and use it as the `since` parameter for subsequent delta syncs.

---

## Article Fields

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `id` | UUID string | Yes | Primary key |
| `titolo` | string | Yes | Italian title |
| `slug` | string | Yes | URL-friendly identifier |
| `categoria` | string | Yes | Category label (Italian, uppercase) |
| `data_pubblicazione` | ISO 8601 string | Soft | Nullable; display "Data non disponibile" if missing |
| `estratto` | string | Yes | Excerpt / teaser |
| `contenuto` | string | Yes | Full body (may contain HTML) |
| `immagine_url` | string | No | Absolute URL to hero image; may be null |
| `updated_at` | ISO 8601 string | Soft | Nullable |
| `sync_version` | integer | Yes | Monotonically increasing |

**Key decoding**: The backend uses `snake_case`. Map to camelCase for your DTO layer (`data_pubblicazione` → `dataPubblicazione`, `immagine_url` → `immagineUrl`, etc.).

---

## Event Fields

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `id` | UUID string | Yes | Primary key |
| `titolo` | string | Yes | Event title |
| `slug` | string | Yes | URL-friendly identifier |
| `tipo` | string | Yes | Event type label |
| `data_evento` | string `"YYYY-MM-DD"` | Yes | Date-only string — do NOT parse as ISO 8601 datetime |
| `ora` | string | Yes | Time as `"HH:mm"` or empty string |
| `luogo` | string | Yes | Location / venue |
| `descrizione` | string | Yes | Description body (may contain HTML) |
| `link` | string | No | External event URL; may be null |
| `immagine_url` | string | No | Hero image URL; may be null |
| `updated_at` | ISO 8601 string | Soft | Nullable |
| `sync_version` | integer | Yes | Monotonically increasing |

**Event date parsing**:
- `data_evento` is `"YYYY-MM-DD"` — parse it with a date-only formatter (`yyyy-MM-dd`, UTC timezone).
- `ora` is `"HH:mm"` — combine with the date for a full datetime. Use this for calendar intent and the `isUpcoming` / `isPast` classification.
- If `data_evento` cannot be parsed, treat the event as undated (`rawDate = null`). Display the raw string as a fallback.

**Upcoming vs past**:
- `isUpcoming`: `rawDate != null && rawDate >= startOfToday()`
- `isPast`: `rawDate != null && rawDate < startOfToday()`
- `isUndated`: `rawDate == null`
- The Home screen shows only upcoming events. It is normal for all events to be past at certain points in the calendar year — show an empty state gracefully.

---

## Document Fields

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `id` | UUID string | Yes | Primary key — the only truly required field |
| `titolo` | string | Soft | Italian title; try `title` as English fallback |
| `slug` | string | Soft | Default to `id` string if missing |
| `tipo` | string | Soft | Document type; try `type` as English fallback; default `""` |
| `categoria` | string | Soft | Category; try `category` as English fallback; default `""` |
| `descrizione` | string | Soft | Description; try `description` fallback; default `""` |
| `url` | string | No | PDF URL — **may be null** |
| `data_caricamento` | ISO 8601 string | Soft | Upload date; try `created_at` as fallback |
| `updated_at` | ISO 8601 string | Soft | Nullable |
| `sync_version` | integer | Soft | Default `0` if missing |

**URL field variants**: The backend has used multiple field names for the document URL. Attempt all of these in order:
1. `url`
2. `file_url`
3. `document_url`
4. `link`

If none resolve to a non-empty string, the document has no PDF. It **must still appear** in the list. Replace the "Open PDF" button with "PDF non disponibile" or an equivalent placeholder.

**Title field variants**: Try `titolo` first, then `title`, then fall back to `"Documento"`.

---

## Date Parsing Rules

The API may return dates in the following formats. Parse them in this priority order:

1. ISO 8601 with fractional seconds: `2026-05-28T10:30:00.123456Z`
2. ISO 8601 without fractional seconds: `2026-05-28T10:30:00Z`
3. Date-only: `2026-05-28` (for `data_evento` specifically; treat as midnight UTC)

If a date field contains an unrecognized format, log the raw string and treat the field as null. **Do not crash.**

---

## Decoding Resilience Rules

These rules are mandatory for the Android implementation:

### 1. Per-item lossy decoding

Never let one malformed item kill the entire array. Wrap each array element decode individually:

```kotlin
// Kotlin / Moshi example
data class LossyList<T>(val items: List<T>)

// Or manually with Gson:
val rawArray = JsonParser.parseString(json).asJsonArray
val results = rawArray.mapNotNull { element ->
    try {
        gson.fromJson(element, DocumentDto::class.java)
    } catch (e: Exception) {
        Log.w("API", "Skipped document item: ${e.message}")
        null
    }
}
```

### 2. Section-level resilience

If the `articles`, `events`, or `documents` key is missing or the wrong type, return an empty list for that section. Do not fail the entire response.

### 3. Null field handling

- Required string fields that are null → use the documented default (`""`, `"Documento"`, etc.)
- Optional URL fields that are null → the object is still valid; show placeholder UI
- Optional date fields that are null → display "Data non disponibile"
- `sync_version` null → default to `0`

### 4. Logging

Log every skipped item (index, error reason) to your internal log system. In debug builds, also log the first 1000 characters of the raw JSON for failed items.

### 5. Cached data on failure

If the network request fails or returns a non-2xx status, keep the previously cached data visible. Show a non-blocking offline warning instead of replacing content with an error screen.

---

## Image URL Handling

- `immagine_url` is an absolute HTTPS URL. Cache-bust aggressively is not needed; Supabase Storage URLs are stable.
- If the URL is null or the image fails to load, show a branded gradient fallback using the article's `categoryColor` palette. The iOS app assigns colors deterministically from `id.uuid.0 % palette.count` so the same article always gets the same fallback gradient.
- Do not show a broken image icon. Always show either the loaded image or the gradient placeholder.

---

## PDF URL Handling

- Document URLs are absolute HTTPS URLs to PDF files (typically Supabase Storage).
- Download to local cache before rendering (do not stream directly into the PDF renderer).
- Show a loading indicator during download.
- On download failure, show an error with a retry button.
- Provide a share button that shares the locally cached file.
- If the document has no URL, never attempt download. Show "PDF non disponibile" text in place of the action button.

---

## Error Handling

| HTTP Status | Handling |
|-------------|----------|
| 200–299 | Decode response |
| 400 | Log, do not retry, show error |
| 401 / 403 | Should not occur (public endpoint). Log. |
| 429 | Retry with exponential backoff (max 2 retries) |
| 500–599 | Retry with exponential backoff (max 2 retries) |
| Network error | Retry up to 2 times with 0.5s / 1.0s delay |

---

## Headers

The iOS app sends the following headers on all requests:

```
Accept: application/json
User-Agent: DiteloSuiTetti-iOS/1.0
```

Android should send:

```
Accept: application/json
User-Agent: DiteloSuiTetti-Android/1.0
```

No `Authorization` header is needed for the editorial sync endpoint.

---

## Production Notes

1. **One malformed item must not crash the whole payload.** Decode arrays item-by-item with individual error catching, as described in the decoding resilience section.

2. **Document URL is not guaranteed.** Any document may have a null URL. The UI must handle this gracefully without filtering out the document from the list.

3. **All events may be past.** The backend does not filter events by date. The app must classify `isUpcoming` / `isPast` client-side. Home shows only upcoming events; if the list is empty, show an empty state, not an error.

4. **Log all failures with sufficient detail** (item index, field path, raw value) to enable debugging without access to the backend database.

5. **Keep cached data visible on sync failure.** Network errors should result in a non-blocking offline banner, not a blank screen.

6. **`serverTime` from the response is the source of truth for delta sync.** Do not use device time as the `since` parameter.
