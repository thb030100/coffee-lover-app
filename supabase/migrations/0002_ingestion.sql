-- Ingestion & promotion columns on shops
-- Adds support for:
--   - admin ingestion (paste from Instagram posts like @bemycoffee.hn)
--   - future partner portal (claimed + promoted shops)

alter table public.shops
  add column source        text not null default 'places'
    check (source in ('places','curated_manual','curated_ig','partner')),
  add column source_url    text,
  add column photo_urls    text[] not null default '{}',
  add column is_promoted   boolean not null default false,
  add column promoted_until timestamptz,
  add column claimed_by    uuid references auth.users(id);

create index shops_source_idx          on public.shops (source);
create index shops_promoted_active_idx on public.shops (is_promoted, promoted_until)
  where is_promoted;

-- Admin bypass: only service_role can write. For the MVP admin tool, call the
-- REST endpoints with the service_role key from a server-side context, never
-- from the Flutter client.
