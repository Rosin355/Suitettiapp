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

### App Version Config (in-app update gating)

```
GET /functions/v1/app-config
```

Public, no auth. Drives the native in-app update prompt. **Status: to be deployed** — until it exists the client receives a non-2xx and silently skips the check (the app is never blocked).

Response:
```json
{
  "latest_ios_version": "1.0.4",
  "minimum_ios_version": "1.0.2",
  "app_store_url": "https://apps.apple.com/app/idXXXXXXXXX",
  "message": "È disponibile una nuova versione di Ditelo sui Tetti."
}
```

| Field | Type | Notes |
|-------|------|-------|
| `latest_ios_version` | string | Newest App Store version. If `current < latest` → **soft** (dismissible) prompt. |
| `minimum_ios_version` | string | Lowest supported version. If `current < minimum` → **forced** (blocking) prompt. |
| `app_store_url` | string | Opened by the "Aggiorna ora" button. |
| `message` | string | Body text shown in the prompt (Italian). |

**Client behaviour** (`AppVersionStore`):
- Current version read from `CFBundleShortVersionString`; compared with a lenient semantic-version comparator (numeric per component — `1.0.10 > 1.0.9` — tolerant of missing parts and pre-release suffixes).
- `minimum` check wins over `latest` (forced beats soft).
- A dismissed soft version is remembered (`UserDefaults: dismissedSoftUpdateVersion`) and not shown again for that same `latest_ios_version`.
- All fields are optional client-side; a missing field is treated as "no constraint". Any fetch/parse failure is logged and ignored.
- Decoded via the shared `.convertFromSnakeCase` decoder, so `latest_ios_version` → `latestIosVersion`, etc.

**Android equivalent**: add the same `app-config` call on launch; compare `BuildConfig.VERSION_NAME`; show a `Dialog`/`ModalBottomSheet` (forced = non-cancelable) and open Play Store (`market://details?id=…`) instead of the App Store URL — the backend can return a separate `play_store_url`/`minimum_android_version`/`latest_android_version` set, or a shared payload with platform-specific keys.

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
| `attachments` | array | No | Optional array of `AttachmentDTO` objects; may be absent or empty |
| `updated_at` | ISO 8601 string | Soft | Nullable |
| `sync_version` | integer | Yes | Monotonically increasing |

**Key decoding**: The backend uses `snake_case`. Map to camelCase for your DTO layer (`data_pubblicazione` → `dataPubblicazione`, `immagine_url` → `immagineUrl`, etc.).

**Attachment fields** (`attachments` array items) — the backend always returns English keys:

| Field | Type | Notes |
|-------|------|-------|
| `id` | UUID string | Attachment primary key |
| `title` | string | Display name; default `"Allegato"` |
| `type` | string | e.g. `"PDF"`, `"Documento"`; default `"PDF"` |
| `description` | string | Optional description; default `""` |
| `url` | string \| null | PDF / file URL; null if not yet uploaded |

The iOS client (`AttachmentDTO`) also accepts Italian field names (`titolo`, `tipo`, `descrizione`) as fallbacks.

If the `attachments` array fails to decode entirely, treat it as empty — never fail the parent article decode.

---

## Event Fields

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `id` | UUID string | Yes | Primary key |
| `titolo` | string | Yes | Event title |
| `slug` | string | Yes | URL-friendly identifier |
| `tipo` | string | Yes | Event type label |
| `data_evento` | string `"YYYY-MM-DD"` | Soft | Date-only string — do NOT parse as ISO 8601 datetime; tolerate null/missing (event becomes undated) |
| `ora` | string | No | Time as `"HH:mm"`; **nullable** — the backend frequently sends `null`. Decode with `decodeIfPresent`; a null `ora` must NOT drop the event |
| `luogo` | string | Soft | Location / venue; tolerate null (default `""`) |
| `descrizione` | string | Soft | Description body (may contain HTML); tolerate null (default `""`) |
| `link` | string | No | External event URL; may be null |
| `immagine_url` | string | No | Hero image URL; may be null |
| `attachments` | array | No | Optional array of `AttachmentDTO` objects; same schema as Article attachments |
| `updated_at` | ISO 8601 string | Soft | Nullable |
| `sync_version` | integer | Yes | Monotonically increasing |
| `is_home_featured` | boolean | Soft | **Home featured banner.** Default `false` when missing/null/wrong-type. Added 2026-08-12 |

**Featured event (`is_home_featured`)**

Backed by `events.is_home_featured` (`boolean NOT NULL DEFAULT false`) and published through the
`mobile_events_public` view. Because `sync-editorial` reads that view with `select("*")` and
spreads every column into the JSON, exposing the field required **no Edge Function change** —
only the view-only migration that appends the existing column. The column, its unique partial
index and the `set_home_featured_event()` RPC already existed — they have driven the public
website's banner since 2026-08-07.

```
CMS "in evidenza" toggle → events.is_home_featured → mobile_events_public
    → sync-editorial → isFeatured → Home featured-event card → native Event Detail
```

- **Not** the same as `is_mobile_visible`. That column gates whether an event is delivered to
  the apps at all; turning it off removes the event entirely. `is_home_featured` only promotes an
  already-visible event to the home banner. (The admin's mobile-visibility toast previously
  read "Evento in evidenza", which described the wrong flag; corrected 2026-08-12.)
- Toggling it bumps `updated_at` and `sync_version` via the existing `trg_editorial_sync`
  trigger, so delta sync picks the change up with no extra work.
- Uniqueness is a **database guarantee**: the unique partial index
  `events_single_home_featured_idx` permits at most one featured non-deleted event. Writes go
  through the `set_home_featured_event()` RPC, which clears the previous winner in the same
  transaction.
- Clients must treat this as the only source of truth for the banner: no hardcoded events, no
  locally persisted banner state. When no event is flagged, no banner renders.

**Event date parsing**:
- `data_evento` is `"YYYY-MM-DD"` — parse it with a date-only formatter (`yyyy-MM-dd`, UTC timezone).
- `ora` is `"HH:mm"` **or null**. When present, combine with the date for a full datetime; when null/empty, use the date alone (midnight). Use this for calendar intent and the `isUpcoming` / `isPast` classification.
- If `data_evento` cannot be parsed, treat the event as undated (`rawDate = null`). Display the raw string as a fallback.

**Event decode resilience (mandatory)**: Only `id` and `titolo` are hard-required. `slug`, `tipo`, `data_evento`, `ora`, `luogo`, `descrizione`, `sync_version`, and `is_home_featured` must all tolerate null/missing/wrong-type with safe defaults — a single malformed field must never drop the event from the list.

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

**URL field variants**: The current backend sends a single `url` field, but the client defensively collects every known variant and **prefers a direct `.pdf` URL over a page URL**:
`url`, `file_url`, `pdf_url`, `document_url`, `attachment_url`, `public_url`, `legacy_url`, `link`. (`.convertFromSnakeCase` maps snake_case → camelCase.)

If none resolve to a non-empty string, the document has no PDF. It **must still appear** in the list. Replace the "Open PDF" button with "PDF non disponibile" or an equivalent placeholder.

**⚠️ Known data caveat (PHASE 6 audit, 2026-06-09)**: 18/25 documents resolve to Supabase storage (`…supabase.co/storage/v1/object/public/document-files/…`) and work (`206 application/pdf`). 7 still carry legacy `www.suitetti.org` URLs — 6 dead `wp-content/*.pdf` (`404`) and 1 WordPress article permalink that serves HTML. These need **backend re-hosting**; the client cannot fix a missing remote file. Android should log status + mime on download and show a graceful error/fallback for non-2xx or non-PDF responses.

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

6. **`server_time` from the response is the source of truth for delta sync.** Do not use device time as the `since` parameter. (The iOS decoder uses `convertFromSnakeCase`, so `server_time` maps automatically to the `serverTime` Swift property.)

---

## allegati Table Schema

The `allegati` table uses a polymorphic `parent_type + parent_id` design rather than separate FK columns per content type.

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID | Primary key |
| `parent_type` | text | `'article'` or `'event'` |
| `parent_id` | UUID | ID of the article or event |
| `title` | text | Attachment display title |
| `type` | text | e.g. `'PDF'`; default `'PDF'` |
| `description` | text | Optional description; nullable |
| `url` | text | Absolute URL to the file |
| `sort_order` | integer | Display order (lower = first); default `0` |
| `is_mobile_visible` | boolean | Mobile read path filter; default `true` |
| `deleted_at` | timestamptz | Soft delete; null = live |
| `created_at` / `updated_at` | timestamptz | Timestamps |
| `sync_version` | bigint | Monotonically increasing; default `1` |

Mobile queries filter: `deleted_at IS NULL AND is_mobile_visible = true`.

The trigger `allegati_bump_parent_updated_at` bumps the parent `articles.updated_at` or `events.updated_at` on any INSERT/UPDATE/DELETE, so delta sync (`?since=`) automatically includes the parent when attachments change.

---

## Backend Deployment — Attachments Pipeline

Steps to put the `attachments` field live. Until deployed, `attachments: []` is returned for every article and event (graceful empty state — no iOS crash).

### Step 0 — Verify schema (confirmation before running migration)

Run this in the Supabase SQL Editor to confirm the real table names:

```sql
select table_name
from information_schema.tables
where table_schema = 'public'
  and table_name in ('articles', 'events', 'documents', 'allegati')
order by table_name;
```

Expected result (before migration): `articles`, `documents`, `events` — three rows.
After migration: four rows including `allegati`.

### Step 1 — Apply the database migration

Migration file: `supabase/migrations/20260605000001_create_allegati.sql`

**Option A — Supabase CLI:**
```bash
supabase db push
```

**Option B — Supabase dashboard SQL Editor:**
1. Open dashboard → select project → **SQL Editor**
2. Paste the full contents of `20260605000001_create_allegati.sql`
3. Execute

What the migration creates:
- `public.allegati` — polymorphic attachment table (`parent_type + parent_id`, no FK constraints)
- Four indexes: `(parent_type, parent_id)`, mobile read path (filtered), `deleted_at IS NULL`, `updated_at DESC`
- `allegati_bump_parent_updated_at` PL/pgSQL trigger — bumps `articles.updated_at` or `events.updated_at` on any attachment change
- RLS policy: `anon` + `authenticated` can SELECT where `deleted_at IS NULL AND is_mobile_visible = true`; no write policy (service-role only)

**Verify migration succeeded:**
```sql
select count(*) from public.allegati;
-- Expected: 0 (empty table, no error means table exists and RLS is set)
```

### Step 2 — Deploy the Edge Function

Function file: `supabase/functions/sync-editorial/index.ts`

**Option A — Supabase CLI:**
```bash
supabase functions deploy sync-editorial
```

**Option B — Supabase Dashboard (if CLI unavailable):**
1. Dashboard → **Edge Functions** → select `sync-editorial`
2. Click **Edit** (or open the function)
3. Replace the entire `index.ts` content with the contents of `supabase/functions/sync-editorial/index.ts`
4. Click **Deploy**

The new function queries `articles`, `events`, `documents`, and `allegati` separately and merges attachments into articles/events by `parent_id`. All existing API fields are preserved unchanged.

### Step 3 — Verify the endpoint

```bash
curl -s "https://kbswgeliohnpwopzzzpc.supabase.co/functions/v1/sync-editorial" \
  | python3 -c "import json,sys; d=json.load(sys.stdin); a=d['articles'][0]; print(a['titolo'], '→ attachments:', a['attachments'])"
```

Expected (before adding data):
```
3° FESTIVAL DELL'"UMANO TUTTO INTERO" → attachments: []
```

If the request returns a 500 error, check the Edge Function logs in the Supabase dashboard for the exact error.

### Step 4 — Add test attachment data

```sql
-- Get a real article id first
select id, titolo from public.articles limit 3;

-- Insert a test attachment (replace the UUID with one from the query above)
insert into public.allegati (parent_type, parent_id, title, type, description, url)
values (
  'article',
  '<paste-article-uuid-here>',
  'Documento di test',
  'PDF',
  'Allegato di prova per verifica pipeline',
  'https://www.w3.org/WAI/WCAG21/Techniques/pdf/PDF2.pdf'
);
```

Re-verify the endpoint shows the attachment:
```bash
curl -s "https://kbswgeliohnpwopzzzpc.supabase.co/functions/v1/sync-editorial" \
  | python3 -c "import json,sys; [print(a['titolo'], len(a['attachments'])) for a in json.load(sys.stdin)['articles'] if a['attachments']]"
```

### Step 5 — Sample JSON response (with attachments)

```json
{
  "server_time": "2026-06-05T21:30:00.000Z",
  "articles": [
    {
      "id": "5c51421b-...",
      "titolo": "3° FESTIVAL DELL'\"UMANO TUTTO INTERO\"",
      "slug": "3-festival-dellumano-tutto-intero",
      "categoria": "Eventi",
      "data_pubblicazione": "2026-06-05T00:00:00+00:00",
      "estratto": "...",
      "contenuto": "<p>...</p>",
      "immagine_url": "https://...",
      "updated_at": "2026-06-05T20:30:25.723325+00:00",
      "sync_version": 2,
      "attachments": [
        {
          "id": "uuid",
          "title": "Documento di test",
          "type": "PDF",
          "description": "Allegato di prova",
          "url": "https://www.w3.org/WAI/WCAG21/Techniques/pdf/PDF2.pdf"
        }
      ]
    }
  ],
  "events": [ ... ],
  "documents": [ ... ]
}
```

### Step 6 — iOS app (no action required)

The iOS app is fully wired for attachments (PHASE-4). After the next sync following backend deployment, articles and events with `allegati` rows will automatically show the "Documenti allegati" / "Documenti dell'evento" section in their detail views. No app update is required.

---

## Proposed: Festival / Project content (Option B — native detail)

A festival is a normal **event** (`tipo: "Festival"`) with its native `EventDetailView` — cover image, description, external `link`, and PDF `attachments`. Like any other event it can be promoted to the Home banner by setting `is_home_featured` (see "Featured event" above).

> The Home "Speciale Festival" card that used to open the website festival hub in the external browser was **removed on 2026-08-12** and replaced by the backend-driven featured-event banner, which opens the **native** event detail. The post-event videos + extra material on the website remain outside this payload — that gap is what Option B below would close.

A fully native `FestivalDetailView` / `ProjectDetailView` (roadmap "Option B") needs two things the current contract does **not** expose.

### 1. Video

No field currently carries a playable video. Add to events (or a new content type):

| Field | Type | Notes |
|-------|------|-------|
| `video_url` | string \| null | Direct MP4/HLS **or** a YouTube/Vimeo watch URL |
| `video_provider` | string \| null | Optional hint: `"youtube"` \| `"vimeo"` \| `"file"` — lets the client choose embed vs. native `AVPlayer` without sniffing the URL |

**Alternative (no schema change)**: deliver videos as typed `attachments` (`type: "video"` + `url`) through the existing polymorphic `allegati` pipeline. The client already tolerates arbitrary attachment types.

### 2. Related articles

No event↔article relationship exists today. Options:

- **Explicit list on the event**: `related_article_ids: [uuid]` (or `related_article_slugs: [string]`) — simplest for the client; resolve against the already-synced `ArticleStore`.
- **Shared project key**: nullable `project_id: uuid` on both `articles` and `events`; the client groups everything with the same key. More flexible if "projects" become first-class (a `projects` table: `title`, `description`, `cover_url`, `video_url`, `website_url`).

**Recommendation**: ship videos as typed `attachments` (zero schema change) and add `related_article_ids` to events — that unlocks Option B without a new content type. Promote to a `projects` table only if festivals/campaigns need a hub independent of a single event date.

Until these ship, the Home festival card (opens `AppEnvironment.festivalURL` in the browser) remains the source of truth for festival videos / extra material.

---

## Push Notification Payload

### Token Registration

```
POST /functions/v1/register-push-token
Content-Type: application/json
```

Request:
```json
{
  "deviceToken": "<hex-string>",
  "platform": "ios",
  "environment": "production",
  "bundleId": "com.romeshsinghabahu.DiteloSuiTetti",
  "appVersion": "1.0.0",
  "buildNumber": "1"
}
```

Response: `{ "ok": true }` or `{ "error": "<message>" }`

### APNs Push Payload

Sent by `send-apns-push` when new content is published:

```json
{
  "aps": {
    "alert": {
      "title": "Ditelo sui Tetti",
      "body": "Nuovo articolo: Sussidiarietà nel territorio"
    },
    "sound": "default"
  },
  "content_type": "article",
  "content_id": "<uuid>",
  "url": "https://www.suitetti.org/articoli/sussidiarieta-nel-territorio"
}
```

**Canonical push URL domain**: `https://www.suitetti.org`

**URL path format**:
- Articles: `https://www.suitetti.org/articoli/{slug}`
- Events: `https://www.suitetti.org/eventi/{slug}`
- Documents: `https://www.suitetti.org/documenti/{slug}`

The iOS app parses `content_type`, `content_id`, and `url` via `NotificationDeepLink(userInfo:)` for deep link routing on tap.

**APNs environment**: `APNS_ENV` Supabase secret must be set to `production` for TestFlight and App Store builds. Debug/Simulator builds use `sandbox`.
