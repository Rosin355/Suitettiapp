# Featured Event — cross-platform specification

Single source of truth for the dynamic "Evento in evidenza" banner on the mobile home.

**Audience:** Android (Jetpack Compose) developers implementing this feature, plus anyone
touching the backend or the iOS implementation. Everything needed is here — you should not
have to read the Swift source to build the Android version.

**Status:** the flag and the website banner have existed since 2026-08-07. iOS client shipped
2026-08-12. The view change that exposes the flag to mobile is committed (2026-08-18) but
**not yet applied to production**, so no app banner renders until it runs. Android pending.

---

## 1. Why this exists

The **website** has had a dynamic featured-event banner since 2026-08-07: an editor toggles
"in evidenza" on the event form and `suitetti.org` promotes it, driven by
`events.is_home_featured`.

The **apps** were left behind. The iOS Home spotlight was a **hardcoded card** pointing at the
3° Festival, so changing what was promoted meant editing Swift and shipping an App Store
release — and the apps could not follow the editor's choice at all, because
`mobile_events_public` never selected the column.

This feature closes that gap: web, iOS and Android now render the same banner from the same
flag. Nothing in any client is bound to a specific event, and **no app release is involved**
when the promoted event changes.

> Never reintroduce a hardcoded Festival banner, a slug allowlist, or a date window that
> "knows" which event matters. The backend decides; clients render.

---

## 2. Database schema

| Property | Value |
|---|---|
| Table | `public.events` |
| Column | `is_home_featured` |
| Type | `boolean` |
| Constraint | `NOT NULL` |
| Default | `false` |
| Index | `events_single_home_featured_idx` — **unique** partial, `ON events((true)) WHERE is_home_featured = true AND deleted_at IS NULL` |
| Written by | `set_home_featured_event(_id uuid, _featured boolean)` RPC — never a direct UPDATE |

The column, its index and the RPC already exist in production. They were added by
`supabase/migrations/20260807102819_…sql` in the **ditelo-on-air** repo, together with the
admin toggle on the event form and the website's `useHomeFeaturedEvent` hook:

```sql
ALTER TABLE public.events
  ADD COLUMN IF NOT EXISTS is_home_featured boolean NOT NULL DEFAULT false;

CREATE UNIQUE INDEX IF NOT EXISTS events_single_home_featured_idx
  ON public.events ((true)) WHERE is_home_featured = true AND deleted_at IS NULL;

CREATE OR REPLACE FUNCTION public.set_home_featured_event(_id uuid, _featured boolean) …
```

> **Do not add a second flag.** `is_home_featured` is the one source of truth for web and
> mobile alike. An earlier draft of this work proposed a parallel `events.is_featured`; that
> was a mistake caused by auditing a stale checkout, and it was discarded before it shipped.

The only mobile-facing change is a **view-only** migration,
`supabase/migrations/20260818120000_expose_home_featured_to_mobile.sql`, which appends the
existing column to `mobile_events_public` so `sync-editorial` publishes it.

### The unique index does the hard work

`events_single_home_featured_idx` makes "at most one featured event" a **database guarantee**,
not a convention. A direct `UPDATE events SET is_home_featured = true` on a second row fails
outright. This is why writes go through `set_home_featured_event()`, which clears the previous
winner before setting the new one, inside one transaction. The RPC is `SECURITY DEFINER` and
checks `is_admin_or_super(auth.uid())`.

Clients still implement the §4.2 tiebreak as defence in depth, but in practice they will never
see two flagged events.

### Behaviour

- Every existing row becomes explicitly `false` on deploy, so no client changes behaviour
  until an editor actually features something.
- Toggling it fires the existing `trg_editorial_sync` trigger, which bumps `updated_at` and
  `sync_version`. Delta sync therefore picks the change up with no extra work.
- Uniqueness is enforced by the database (unique partial index), and the RPC clears the
  previous winner in the same transaction — so at most one row is ever `true`.

### ⚠️ `is_home_featured` is NOT `is_mobile_visible`

These are different columns with different jobs. Confusing them is destructive:

| Column | Meaning | Turning it off |
|---|---|---|
| `is_mobile_visible` | Does this event sync to the apps **at all**? | Event **disappears entirely** from both apps |
| `is_home_featured` | Is this event promoted to the home banner? | Banner disappears; event stays in the list |

Until 2026-08-12 the admin showed a success toast reading *"Evento in evidenza"* on the
`is_mobile_visible` switch — a copy bug, now fixed. All currently synced events have
`is_mobile_visible = true`.

---

## 3. Public API

### Exposure

`is_home_featured` is appended as the final column of the `public.mobile_events_public` view:

```sql
CREATE OR REPLACE VIEW public.mobile_events_public AS
SELECT
  id, titolo, slug, tipo, data_evento, ora, luogo, descrizione,
  link, immagine_url, updated_at, sync_version,
  is_home_featured
FROM public.events
WHERE deleted_at IS NULL
  AND status = 'published'
  AND is_mobile_visible = true;
```

**No Edge Function change was required.** `sync-editorial` reads the view with `select("*")`
and spreads every column into the JSON, so the field publishes itself the moment the view has
it — to iOS, Android and anything built later, simultaneously. (The website does not go through
this endpoint at all; it queries `events` directly.)

### Endpoint

```
GET https://kbswgeliohnpwopzzzpc.supabase.co/functions/v1/sync-editorial
GET https://kbswgeliohnpwopzzzpc.supabase.co/functions/v1/sync-editorial?since=<ISO8601>
```

Public, no authentication.

### Response

`is_home_featured` appears on **every** event object, not in a separate `featured_event` key:

```json
{
  "server_time": "2026-08-12T13:49:40.000Z",
  "articles": [ ... ],
  "documents": [ ... ],
  "events": [
    {
      "id": "327f9257-0aec-43c0-a796-de6046595868",
      "titolo": "3° FESTIVAL DELL'UMANO TUTTO INTERO",
      "slug": "evento-3-festival-dellumano-tutto-intero",
      "tipo": "evento",
      "data_evento": "2026-10-16",
      "ora": null,
      "luogo": "Pio Sodalizio dei Piceni, Roma",
      "descrizione": "Programma del festival…",
      "link": null,
      "immagine_url": null,
      "updated_at": "2026-06-12T10:49:16.113261+00:00",
      "sync_version": 6,
      "is_home_featured": true,
      "attachments": [
        {
          "id": "…",
          "title": "PROGRAMMA.pdf",
          "type": "PDF",
          "description": null,
          "url": "https://…/PROGRAMMA.pdf"
        }
      ]
    }
  ]
}
```

> **Field names are Italian snake_case.** There is no `title`, `date`, `location`, or
> `cover_url`. The real keys are `titolo`, `data_evento`, `ora`, `luogo`, `immagine_url`.
> `data_evento` is a **date-only** `"YYYY-MM-DD"` string — do not parse it as ISO 8601
> datetime. `ora` is `"HH:mm"` **or null**, and null is common.

### Decoding rules (mandatory)

`is_home_featured` must be decoded **defensively**, exactly like every other optional event field:

| Wire value | Decoded |
|---|---|
| `true` | `true` |
| `false` | `false` |
| key absent | `false` |
| `null` | `false` |
| wrong type (`"yes"`, `1`, …) | `false`, and **the event must still decode** |

A malformed `is_home_featured` must never drop the event from the list. Only `id` and `titolo` are
hard-required on an event.

This also means clients are **forward- and backward-compatible**: an app running against a
backend without the column simply sees `false` everywhere and renders no banner.

---

## 4. Business rules

### 4.1 One featured event

Exactly zero or one event is featured, and this is **enforced by the database** via the unique
partial index `events_single_home_featured_idx`. The `set_home_featured_event()` RPC clears the
previous winner before setting the new one, so switching the promoted event is a single
transaction and never leaves two rows flagged.

### 4.2 Resolution when several are flagged

In practice unreachable — the unique index forbids it — but every client **must** still handle
it defensively: deterministically, without crashing, and without the banner flickering between
candidates on successive syncs. Treat this as belt-and-braces against a future schema change
that drops the index.

Ordering, first match wins:

1. **Upcoming beats past/undated** — an event whose date is today or later.
2. **Nearest event date** — soonest first among upcoming; most recent first among past. A
   dated event always beats an undated one.
3. **Newest `updated_at`.**
4. **Lowest `id`** — the total-order tiebreak. Without it, two otherwise-identical events can
   swap places between launches and the banner appears to flicker.

Log a warning when this path is taken. iOS logs:

```
[FeaturedEvent] ⚠️ 4 events flagged featured — resolving deterministically: A | B | C | D
```

### 4.3 No featured event

The banner **disappears completely** — no placeholder, no empty card, no reserved vertical
space, no "coming soon" state. The section renders nothing.

### 4.4 A featured past event still shows

The flag is independent of the date. If an editor features an event that has already happened,
it is promoted. The backend decides what is worth promoting; clients do not second-guess it.

### 4.5 Derive, never store

The featured event is computed from the current event list on **every read**. It is never
persisted as its own record, key, or remembered id. This is precisely what makes the banner
vanish on its own when an editor clears the flag.

---

## 5. Android behaviour

What Android must do, concretely:

1. **Read `is_home_featured`** from the existing events array — nullable Boolean, default `false`.
2. **Resolve the winner** with the §4.2 ordering; expose it as derived state
   (`StateFlow<Event?>`), never as a stored field.
3. **Cache it as part of the event row** (`cached_events.isFeatured`), never as a separate
   "banner" table or DataStore key.
4. **Invalidate the cache when the flag changes** — see §7. This is not optional.
5. **Render the banner only when the resolved value is non-null.** Emit nothing otherwise.
6. **Open the native Event Detail screen** on tap — the same destination used by the events
   list. The whole card is one tap target (≥48 dp) and one merged accessibility node.
7. **Fall back to the brand artwork** when `immagine_url` is null or the load fails (Coil
   fallback painter, same asset as everywhere else). Never a gradient, never a blank box.
8. **Never open an external website** from this banner.
9. **Never hardcode a Festival banner**, a slug, a date window, or "the latest event".

### Reference implementation

```kotlin
// ── DTO — tolerant by default ────────────────────────────────────────────────
@Serializable
data class EventDto(
    // … existing fields …
    @SerialName("is_home_featured") val isFeatured: Boolean? = null,
)

// ── Domain model ─────────────────────────────────────────────────────────────
data class Event(
    // … existing fields …
    val isFeatured: Boolean = false,
)

fun EventDto.toEvent() = Event(
    // … existing mappings …
    isFeatured = isFeatured ?: false,
)

// ── Room — additive migration, never fallbackToDestructiveMigration() ────────
val MIGRATION_N = object : Migration(N - 1, N) {
    override fun migrate(db: SupportSQLiteDatabase) {
        db.execSQL("ALTER TABLE cached_events ADD COLUMN isFeatured INTEGER NOT NULL DEFAULT 0")
    }
}

// ── Resolution — mirrors iOS EventStore.resolveFeatured ──────────────────────
fun resolveFeatured(events: List<Event>): Event? {
    val flagged = events.filter { it.isFeatured }
    if (flagged.size <= 1) return flagged.firstOrNull()

    Log.w("FeaturedEvent", "${flagged.size} events flagged featured — resolving deterministically")
    return flagged.sortedWith(
        compareBy<Event> { if (it.isUpcoming) 0 else 1 }
            .thenBy { if (it.isUpcoming) it.rawDate ?: Long.MAX_VALUE else -(it.rawDate ?: Long.MIN_VALUE) }
            .thenByDescending { it.updatedAt ?: Long.MIN_VALUE }
            .thenBy { it.id }            // total order → winner never flickers
    ).first()
}

// ── Derived state — clearing the flag removes the banner automatically ───────
val featuredEvent: StateFlow<Event?> = events
    .map(::resolveFeatured)
    .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), null)
```

```kotlin
// ── Compose — render nothing when null ───────────────────────────────────────
val featured by viewModel.featuredEvent.collectAsStateWithLifecycle()
featured?.let { event ->
    HomeFeaturedEventCard(
        event = event,
        onClick = { navController.navigate("events/${event.id}") },
    )
}
// No else branch. No placeholder. No Spacer.
```

### Home placement and de-duplication

Order on Home: hero → ticker → "In evidenza" (articles) → **featured-event banner** →
"Prossimi eventi" → quote.

Filter the promoted event out of the "Prossimi eventi" preview so it does not appear twice in
one screenful. If it was the *only* upcoming event, hide that whole section rather than showing
"Nessun evento in programma" directly under a banner advertising an upcoming event. The full
events list still shows it.

Visual spec and accessibility contract: `UI_COMPONENTS.md` → "Addendum — HomeFeaturedEventCard".

---

## 6. Synchronization

- **Reuse `sync-editorial`.** It already returns the field on every event.
- **No dedicated endpoint.** There is no `/featured-event` and there must not be one.
- **No polling.** The banner updates on the app's existing sync triggers: launch, and
  foreground resume when the cache is stale (iOS threshold: 10 minutes).
- **No new Edge Functions.** None were needed for iOS and none are needed for Android.
- **No per-platform API.** One endpoint serves web, iOS, Android and anything built later.

Because the sync replaces store contents **wholesale on every successful sync** (not only when
the cache is rewritten), clearing the flag backend-side removes the banner as soon as that sync
lands.

---

## 7. Caching

### The rule

**`is_home_featured` must be part of the cache-invalidation signature.**

### Why — this is a real bug, already hit once

The cache signature is a hash over the payload used to decide whether to rewrite the persisted
cache. iOS originally hashed only event `id`, `title` and `description`.

Clearing `is_home_featured` usually changes **nothing else** about the event. So with a text-only
signature:

1. Admin un-features the event.
2. Sync runs, in-memory stores update, banner disappears. Looks correct.
3. Signature is unchanged → persisted cache is **not** rewritten → it still holds
   `isFeatured = true`.
4. Next cold start restores the cache → **the banner flashes back** until the sync completes.

iOS fixed this by feeding the flag into `contentSignature`:

```swift
for e in events {
    feed(e.id.uuidString); feed(e.title); feed(e.description)
    feed(e.isFeatured ? "F1" : "F0")
}
```

Android must do the equivalent in whatever hash/version decides a Room rewrite.

### Cold-start flow

```
launch
  → restore cached events
  → banner shows if a cached event is featured   (works offline)
  → live sync
  → stores replaced wholesale
  → banner reflects the backend
```

### Migration

Additive only. `ALTER TABLE cached_events ADD COLUMN isFeatured INTEGER NOT NULL DEFAULT 0` —
a real Room migration, **not** `fallbackToDestructiveMigration()`, so users keep offline
content. Old rows read `false`, which is the correct pre-sync state.

iOS deliberately did **not** bump its cache schema version for the same reason: the property
carries a default, so SwiftData migrates existing stores automatically.

### Diagnostics

Log these around the point where the store is replaced after a successful sync. They turn a
"the banner won't go away" report into a one-line diagnosis:

```
[FeaturedEvent] cached=<title or nil>
[FeaturedEvent] remote=<title or nil>
[FeaturedEvent] final=<title or nil>
```

---

## 8. Cross-platform architecture

```
                    ┌──────────────────────────┐
                    │   CMS admin toggle       │
                    │  "in evidenza" (exclusive)│
                    └────────────┬─────────────┘
                                 ▼
                       events.is_home_featured          ← single source of truth
                                 │
                                 ▼
                      mobile_events_public          (view; column appended last)
                                 │
                                 ▼
                        sync-editorial              (select("*") — one endpoint, no auth)
                                 │
                 ┌───────────────┼───────────────┐
                 ▼               ▼               ▼
               Web             iOS            Android
                                 │               │
                                 ▼               ▼
                          Featured banner → native Event Detail
```

**The backend is the single source of truth. No platform may add its own logic** for choosing
what is promoted — no date windows, no `tipo == "Festival"` checks, no slug allowlists, no
"most recent event" heuristics. Clients read the flag, apply the deterministic tiebreak in
§4.2, and render.

### Per-platform status

| Platform | Writes the flag | Reads the flag | Renders a banner |
|---|---|---|---|
| **Admin (web)** | ✅ event-form toggle → `set_home_featured_event()` RPC | ✅ | n/a |
| **Public website** | — | ✅ `useHomeFeaturedEvent` hook (since 2026-08-07) | ✅ home banner |
| **iOS** | — | ✅ client shipped 2026-08-12 | ⏳ blocked on the view migration |
| **Android** | — | ⏳ pending — spec is §5 | ⏳ pending |

All four read one column. The admin is the only writer, and it writes through the RPC so the
uniqueness guarantee holds.

> **Current blocker.** `mobile_events_public` does not yet expose the column in production, so
> `sync-editorial` omits it, every event decodes as `false`, and the app banner stays hidden.
> The website banner is unaffected — it queries `events` directly. Applying
> `20260818120000_expose_home_featured_to_mobile.sql` is the single step that lights up mobile.

---

## 9. QA checklist

Run `scripts/verify-featured-event.sh` first — it reports, with no credentials, whether the
migration is live, which event is promoted, and which winner the tiebreak picks.

| # | Scenario | Expected |
|---|---|---|
| **A** | No featured event | Banner **hidden**. No placeholder, no empty space. |
| **B** | Admin enables featured | Banner **appears after the next sync** with correct title, date, location, image; tap opens the **native** Event Detail. |
| **C** | Admin features a different event | Previous banner **disappears**, new one appears. (One admin action — the toggle is exclusive.) |
| **D** | Admin disables featured | Banner **disappears** after the next sync, and **stays gone after a cold restart** (this is the cache-signature check). |
| **E** | Featured event has no cover image | Official brand fallback artwork. Never a gradient or blank box. |
| **F** | Offline launch | Last cached featured event renders from cache; state reconciles with the backend once connectivity returns. |
| **G** | Several events flagged (direct DB edit) | Deterministic winner per §4.2, warning logged, no crash, no flicker across repeated syncs. |
| **H** | Backend without the column | Every event decodes `false`, no banner, **existing sync unaffected**. |

### iOS verification results (2026-08-12)

- Automated: 23/23 checks passing in a harness compiling the real `Event`, `EventDTO`,
  `EventStore` and `EditorialCachePolicy` sources — covers A–H including all 63 live events
  still decoding.
- Runtime vs live backend: `sync OK — articles: 301, events: 63, documents: 27`,
  `[SyncDiag] events flagged featured: 0`, `[FeaturedEvent] cached=nil / remote=nil / final=nil`.
- Visual (iPad, `--screenshots`): banner, brand fallback (E), placement, and Home
  de-duplication confirmed.
- Scenarios B, C, D and F **against production data** are pending the migration.

### Android definition of done

A, C, E and G are testable with local fixtures today — no backend required. B, D and F need
the migration applied. H is the current production state, so it is testable immediately and
should be the **first** thing verified: adding the field must not change anything yet.

---

## 10. Related documents

| Document | What it adds |
|---|---|
| `API_CONTRACT.md` | Full event field table + decode-resilience rules |
| `DATA_MODELS.md` | `is_home_featured` in the DTO/domain/Room model tables |
| `UI_COMPONENTS.md` | `HomeFeaturedEventCard` visual + accessibility spec |
| `APP_FLOW.md` | Where the banner sits on Home and how it behaves across launch/sync |
| `ANDROID_CONVERSION_GUIDE.md` | Compose parity rules and the zero-backend-work guarantee |
| `ROADMAP.md` | Delivery status and the pending production step |
| `../scripts/verify-featured-event.sh` | Credential-free contract verifier |
