/**
 * sync-editorial
 *
 * Public read-only Edge Function returning all editorial content for the
 * Ditelo sui Tetti iOS and Android apps.
 *
 * Endpoints:
 *   GET /functions/v1/sync-editorial             → full sync (all items)
 *   GET /functions/v1/sync-editorial?since=...   → delta sync (updated_at > since)
 *
 * Response shape (unchanged from previous version + attachments added):
 *   {
 *     server_time:  string (ISO 8601),
 *     articles:     ArticleOut[],   // each includes attachments: []
 *     events:       EventOut[],     // each includes attachments: []
 *     documents:    DocumentOut[]
 *   }
 *
 * Attachments are fetched in a single query on the allegati table and merged
 * into articles/events client-side (avoids PostgREST embedded-relation
 * limitation with polymorphic parent_type + parent_id FK-less design).
 *
 * Only visible, non-deleted allegati are included:
 *   WHERE is_mobile_visible = true AND deleted_at IS NULL
 * Ordered by sort_order ASC, created_at ASC.
 *
 * Delta sync + attachments: the trigger allegati_bump_parent_updated_at bumps
 * the parent article/event updated_at whenever an allegato changes, so delta
 * queries automatically re-include the parent.
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// ─── CORS ─────────────────────────────────────────────────────────────────────

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// ─── DB row types ─────────────────────────────────────────────────────────────

interface ArticleRow {
  id: string
  titolo: string
  slug: string
  categoria: string
  data_pubblicazione: string | null
  estratto: string
  contenuto: string
  immagine_url: string | null
  updated_at: string
  sync_version: number
}

interface EventRow {
  id: string
  titolo: string
  slug: string
  tipo: string
  data_evento: string
  ora: string | null
  luogo: string
  descrizione: string
  link: string | null
  immagine_url: string | null
  updated_at: string
  sync_version: number
}

interface DocumentRow {
  id: string
  titolo: string | null
  slug: string | null
  tipo: string | null
  categoria: string | null
  descrizione: string | null
  url: string | null
  data_caricamento: string | null
  updated_at: string | null
  sync_version: number | null
}

interface AllegatoRow {
  id: string
  parent_type: string
  parent_id: string
  title: string
  type: string
  description: string | null
  url: string
  sort_order: number
  created_at: string
}

// ─── Output types (passed through to iOS/Android) ─────────────────────────────
//
// Field names are kept in Italian snake_case to match the existing live API
// contract. The iOS JSONDecoder uses .convertFromSnakeCase so both snake_case
// and camelCase work, but preserving the existing keys avoids any rollback risk.

interface AttachmentOut {
  id: string
  title: string
  type: string
  description: string
  url: string
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

function buildAttachmentMap(rows: AllegatoRow[]): Map<string, AttachmentOut[]> {
  const map = new Map<string, AttachmentOut[]>()
  for (const row of rows) {
    const att: AttachmentOut = {
      id:          row.id,
      title:       row.title,
      type:        row.type || 'PDF',
      description: row.description ?? '',
      url:         row.url,
    }
    const list = map.get(row.parent_id) ?? []
    list.push(att)
    map.set(row.parent_id, list)
  }
  return map
}

function mapArticle(row: ArticleRow, attachments: AttachmentOut[]) {
  return {
    id:                 row.id,
    titolo:             row.titolo,
    slug:               row.slug,
    categoria:          row.categoria,
    data_pubblicazione: row.data_pubblicazione ?? null,
    estratto:           row.estratto,
    contenuto:          row.contenuto,
    immagine_url:       row.immagine_url ?? null,
    updated_at:         row.updated_at,
    sync_version:       row.sync_version,
    attachments,
  }
}

function mapEvent(row: EventRow, attachments: AttachmentOut[]) {
  return {
    id:          row.id,
    titolo:      row.titolo,
    slug:        row.slug,
    tipo:        row.tipo,
    data_evento: row.data_evento,
    ora:         row.ora ?? '',
    luogo:       row.luogo,
    descrizione: row.descrizione,
    link:        row.link ?? null,
    immagine_url: row.immagine_url ?? null,
    updated_at:  row.updated_at,
    sync_version: row.sync_version,
    attachments,
  }
}

function mapDocument(row: DocumentRow) {
  return {
    id:              row.id,
    titolo:          row.titolo ?? 'Documento',
    slug:            row.slug ?? row.id,
    tipo:            row.tipo ?? '',
    categoria:       row.categoria ?? '',
    descrizione:     row.descrizione ?? '',
    url:             row.url ?? null,
    data_caricamento: row.data_caricamento ?? null,
    updated_at:      row.updated_at ?? null,
    sync_version:    row.sync_version ?? 0,
  }
}

// ─── Main handler ─────────────────────────────────────────────────────────────

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  if (req.method !== 'GET') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // ?since= parameter for delta sync
  const reqUrl = new URL(req.url)
  const since = reqUrl.searchParams.get('since')

  if (since && isNaN(Date.parse(since))) {
    return new Response(
      JSON.stringify({ error: 'Invalid `since` parameter — expected ISO 8601' }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
  )

  const serverTime = new Date().toISOString()

  try {
    // ── Articles ─────────────────────────────────────────────────────────────

    let articlesQuery = supabase
      .from('articles')
      .select('id, titolo, slug, categoria, data_pubblicazione, estratto, contenuto, immagine_url, updated_at, sync_version')
      .order('data_pubblicazione', { ascending: false, nullsFirst: false })

    if (since) {
      articlesQuery = articlesQuery.gt('updated_at', since)
    }

    const { data: articlesData, error: articlesErr } = await articlesQuery
    if (articlesErr) {
      console.error('[sync-editorial] articles query failed:', articlesErr.message)
      throw articlesErr
    }

    // ── Events ───────────────────────────────────────────────────────────────

    let eventsQuery = supabase
      .from('events')
      .select('id, titolo, slug, tipo, data_evento, ora, luogo, descrizione, link, immagine_url, updated_at, sync_version')
      .order('data_evento', { ascending: true })

    if (since) {
      eventsQuery = eventsQuery.gt('updated_at', since)
    }

    const { data: eventsData, error: eventsErr } = await eventsQuery
    if (eventsErr) {
      console.error('[sync-editorial] events query failed:', eventsErr.message)
      throw eventsErr
    }

    // ── Documents ────────────────────────────────────────────────────────────

    let documentsQuery = supabase
      .from('documents')
      .select('id, titolo, slug, tipo, categoria, descrizione, url, data_caricamento, updated_at, sync_version')
      .order('data_caricamento', { ascending: false, nullsFirst: false })

    if (since) {
      documentsQuery = documentsQuery.gt('updated_at', since)
    }

    const { data: documentsData, error: documentsErr } = await documentsQuery
    if (documentsErr) {
      console.error('[sync-editorial] documents query failed:', documentsErr.message)
      throw documentsErr
    }

    // ── Allegati (all visible, non-deleted) ───────────────────────────────────
    //
    // Fetch all attachments in one query and merge into articles/events by
    // parent_id. We do NOT filter by since here — we always want the full
    // attachment set for the articles/events returned in this response, so that
    // a delta sync that returns an article due to an allegato change also
    // returns the complete current attachment list for that article.

    const { data: allegatiData, error: allegatiErr } = await supabase
      .from('allegati')
      .select('id, parent_type, parent_id, title, type, description, url, sort_order, created_at')
      .is('deleted_at', null)
      .eq('is_mobile_visible', true)
      .order('sort_order', { ascending: true })
      .order('created_at', { ascending: true })

    if (allegatiErr) {
      // Non-fatal: log and continue with empty attachments rather than failing the whole response
      console.error('[sync-editorial] allegati query failed (continuing without):', allegatiErr.message)
    }

    // ── Merge ─────────────────────────────────────────────────────────────────

    const attachmentMap = buildAttachmentMap((allegatiData ?? []) as AllegatoRow[])

    const articles  = (articlesData  ?? []).map((r) => mapArticle(r as ArticleRow,  attachmentMap.get(r.id) ?? []))
    const events    = (eventsData    ?? []).map((r) => mapEvent(r as EventRow,      attachmentMap.get(r.id) ?? []))
    const documents = (documentsData ?? []).map((r) => mapDocument(r as DocumentRow))

    // ── Diagnostics ───────────────────────────────────────────────────────────

    const totalAttachments = [...attachmentMap.values()].reduce((n, a) => n + a.length, 0)
    console.log(
      `[sync-editorial] OK — articles: ${articles.length}, events: ${events.length}, documents: ${documents.length}, attachments: ${totalAttachments}${since ? ` (since ${since})` : ''}`,
    )
    for (const a of articles.slice(0, 5)) {
      if (a.attachments.length > 0) {
        console.log(`  article ${a.id} (${a.slug}): ${a.attachments.length} attachment(s)`)
      }
    }
    for (const e of events.slice(0, 5)) {
      if (e.attachments.length > 0) {
        console.log(`  event   ${e.id} (${e.slug}): ${e.attachments.length} attachment(s)`)
      }
    }

    return new Response(
      JSON.stringify({ server_time: serverTime, articles, events, documents }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err)
    console.error('[sync-editorial] unhandled error:', message)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
