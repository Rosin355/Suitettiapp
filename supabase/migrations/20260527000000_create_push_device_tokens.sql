-- push_device_tokens: stores APNs device tokens for server-side push delivery
create table if not exists public.push_device_tokens (
    id              uuid        primary key default gen_random_uuid(),
    device_token    text        not null unique,
    platform        text        not null default 'ios',
    environment     text        not null check (environment in ('sandbox', 'production')),
    bundle_id       text        not null,
    app_version     text,
    build_number    text,
    is_enabled      boolean     not null default true,
    last_seen_at    timestamptz not null default now(),
    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now()
);

-- Indexes
create unique index if not exists push_device_tokens_device_token_idx
    on public.push_device_tokens (device_token);

create index if not exists push_device_tokens_environment_idx
    on public.push_device_tokens (environment);

create index if not exists push_device_tokens_is_enabled_idx
    on public.push_device_tokens (is_enabled);

-- RLS: enabled; no anon access — all mutations go through the Edge Function (service role)
alter table public.push_device_tokens enable row level security;
