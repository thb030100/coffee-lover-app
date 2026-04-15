-- Coffee Lover initial schema
-- Target: Supabase (Postgres 15)
-- Extensions assumed enabled by Supabase: pgcrypto (gen_random_uuid), uuid-ossp

-- ─────────────────────────────────────────────────────────────────────────────
-- shops: canonical coffee shop table, seeded from Google Places + overrides
-- ─────────────────────────────────────────────────────────────────────────────
create table public.shops (
  id              uuid primary key default gen_random_uuid(),
  google_place_id text unique,
  name            text not null,
  name_vi         text,
  lat             double precision not null,
  lng             double precision not null,
  address         text,
  price_level     smallint check (price_level between 1 and 4),
  google_rating   numeric(2,1) check (google_rating between 0 and 5),
  tags            text[] not null default '{}',
  photo_refs      text[] not null default '{}',
  hours           jsonb,
  phone           text,
  is_curated      boolean not null default false,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index shops_lat_lng_idx on public.shops (lat, lng);
create index shops_tags_gin    on public.shops using gin (tags);

-- ─────────────────────────────────────────────────────────────────────────────
-- profiles: one row per authenticated user, mirrors auth.users
-- ─────────────────────────────────────────────────────────────────────────────
create table public.profiles (
  id            uuid primary key references auth.users(id) on delete cascade,
  display_name  text,
  preferences   jsonb not null default '{}'::jsonb,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- Auto-create a profile row on signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, new.raw_user_meta_data->>'full_name');
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ─────────────────────────────────────────────────────────────────────────────
-- swipes: every swipe the user makes — the raw signal for future algo work
-- ─────────────────────────────────────────────────────────────────────────────
create table public.swipes (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles(id) on delete cascade,
  shop_id     uuid not null references public.shops(id) on delete cascade,
  direction   text not null check (direction in ('left','right','up')),
  created_at  timestamptz not null default now()
);

create index swipes_user_created_idx on public.swipes (user_id, created_at desc);
create index swipes_user_shop_idx    on public.swipes (user_id, shop_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- saved_shops: materialized up-swipes for fast profile reads
-- ─────────────────────────────────────────────────────────────────────────────
create table public.saved_shops (
  user_id   uuid not null references public.profiles(id) on delete cascade,
  shop_id   uuid not null references public.shops(id) on delete cascade,
  saved_at  timestamptz not null default now(),
  primary key (user_id, shop_id)
);

-- ─────────────────────────────────────────────────────────────────────────────
-- Row Level Security
-- ─────────────────────────────────────────────────────────────────────────────
alter table public.shops       enable row level security;
alter table public.profiles    enable row level security;
alter table public.swipes      enable row level security;
alter table public.saved_shops enable row level security;

-- shops: readable by any authenticated user, writable only by service_role
create policy "shops readable by authenticated"
  on public.shops for select
  to authenticated
  using (true);

-- profiles: user owns their row
create policy "profiles select own"
  on public.profiles for select
  to authenticated
  using (id = auth.uid());

create policy "profiles update own"
  on public.profiles for update
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

-- swipes: user owns their swipes
create policy "swipes select own"
  on public.swipes for select
  to authenticated
  using (user_id = auth.uid());

create policy "swipes insert own"
  on public.swipes for insert
  to authenticated
  with check (user_id = auth.uid());

-- saved_shops: user owns their saves
create policy "saved_shops select own"
  on public.saved_shops for select
  to authenticated
  using (user_id = auth.uid());

create policy "saved_shops insert own"
  on public.saved_shops for insert
  to authenticated
  with check (user_id = auth.uid());

create policy "saved_shops delete own"
  on public.saved_shops for delete
  to authenticated
  using (user_id = auth.uid());
