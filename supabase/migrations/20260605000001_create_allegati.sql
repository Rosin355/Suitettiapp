-- allegati: PDF/document attachments for articles and events
--
-- Uses a polymorphic parent reference (parent_type + parent_id) to avoid
-- two separate FK columns and the awkward partial-index FK pattern.
-- No foreign key constraints are defined — referential integrity is enforced
-- by the application layer and the parent_type check constraint.
--
-- parent_type = 'article'  →  parent_id references public.articles(id)
-- parent_type = 'event'    →  parent_id references public.events(id)

create table if not exists public.allegati (
    id                  uuid        primary key default gen_random_uuid(),

    -- Polymorphic parent reference
    parent_type         text        not null
                        check (parent_type in ('article', 'event')),
    parent_id           uuid        not null,

    -- Attachment content
    title               text        not null,
    type                text        not null default 'PDF',
    description         text,
    url                 text        not null,

    -- Display control
    sort_order          integer     not null default 0,
    is_mobile_visible   boolean     not null default true,

    -- Soft delete (never hard-delete; mobile queries filter deleted_at IS NULL)
    deleted_at          timestamptz,

    -- Timestamps and sync
    created_at          timestamptz not null default now(),
    updated_at          timestamptz not null default now(),
    sync_version        bigint      not null default 1
);

-- ─── Indexes ─────────────────────────────────────────────────────────────────

-- Primary lookup: all attachments for a given parent
create index if not exists allegati_parent_idx
    on public.allegati (parent_type, parent_id);

-- Mobile read path: only visible, non-deleted attachments
create index if not exists allegati_mobile_visible_idx
    on public.allegati (parent_type, parent_id, sort_order, created_at)
    where is_mobile_visible = true and deleted_at is null;

-- Filtered index for live (non-deleted) rows
create index if not exists allegati_not_deleted_idx
    on public.allegati (deleted_at)
    where deleted_at is null;

-- Updated_at index for future delta-sync on allegati itself
create index if not exists allegati_updated_at_idx
    on public.allegati (updated_at desc);

-- ─── Delta-sync trigger ───────────────────────────────────────────────────────
--
-- When an allegato is inserted, updated, or deleted, bump the parent article or
-- event's `updated_at`. This ensures that delta sync (?since=...) automatically
-- re-syncs the parent when its attachments change — even if the parent body was
-- not edited.

create or replace function public.allegati_bump_parent_updated_at()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
    _parent_type text;
    _parent_id   uuid;
begin
    if tg_op = 'DELETE' then
        _parent_type := old.parent_type;
        _parent_id   := old.parent_id;
    else
        _parent_type := new.parent_type;
        _parent_id   := new.parent_id;
    end if;

    if _parent_type = 'article' then
        update public.articles set updated_at = now() where id = _parent_id;
    elsif _parent_type = 'event' then
        update public.events set updated_at = now() where id = _parent_id;
    end if;

    return coalesce(new, old);
end;
$$;

create trigger allegati_bump_parent
    after insert or update or delete
    on public.allegati
    for each row
    execute function public.allegati_bump_parent_updated_at();

-- ─── Row-level security ───────────────────────────────────────────────────────
--
-- Mobile clients (anon / authenticated) may read visible, non-deleted attachments.
-- All writes are CMS / service-role only (no insert/update/delete policy = denied).

alter table public.allegati enable row level security;

create policy "allegati: public read (visible and not deleted)"
    on public.allegati
    for select
    to anon, authenticated
    using (
        deleted_at is null
        and is_mobile_visible = true
    );
