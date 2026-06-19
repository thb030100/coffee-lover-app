# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project status

MVP client is scaffolded and largely implemented. `pubspec.yaml` and the platform folders (`ios/`, `android/`, `macos/`, `web/`, `linux/`, `windows/`) all exist. Implemented features: Apple/Google sign-in, preferences onboarding, the swipe deck with geolocation + local filtering, Today's Pick, the saved-shops profile, and the shop detail sheet.

Not yet done before it runs end-to-end: a live Supabase project with the `supabase/migrations/` applied, a real `.env` (copied from `.env.example`), and a seeded `shops` table (`dart run tools/seed_hanoi.dart`). The Flutter toolchain must be installed locally to build, analyze, and test.

The approved product plan — scope, phased roadmap, data model rationale, post-MVP partner portal design — lives at `~/.claude/plans/agile-fluttering-petal.md` (outside this repo; keep a copy when working on a fresh machine). Read it before proposing architectural changes.

## Commands

Post-`flutter create`, the expected workflow is:

```bash
flutter pub get                  # install packages
flutter run -d <device>          # run on a physical iPhone or simulator
flutter analyze                  # static analysis
flutter test                     # run all tests
flutter test test/path/file.dart # run a single test file
dart run tools/seed_hanoi.dart   # one-off Places → Supabase seed (needs .env)
```

SQL migrations are applied by pasting into the Supabase dashboard SQL editor, in numeric order. There is no Supabase CLI wiring yet.

## Architecture

The app is a Bumble-style coffee shop discovery client. Data flows in one direction at runtime and two directions at ingest time:

**Runtime** (read-only for the client):
```
Flutter client ──▶ Supabase (shops, swipes, saved_shops, profiles)
```
The client never calls Google Places at runtime. It reads from `shops` (populated ahead of time), filters locally via `RecommendationService`, and writes swipe events back to Supabase.

**Ingest** (offline, admin-only):
```
Google Places API ──▶ tools/seed_hanoi.dart ──▶ Supabase.shops
Instagram / manual ──▶ admin web tool        ──▶ Supabase.shops   (future)
Partner portal     ──▶ partner_submissions   ──▶ Supabase.shops   (post-MVP)
```
`shops.source` distinguishes provenance (`places | curated_manual | curated_ig | partner`). The client treats all sources identically — merging happens at ingest, not read.

### Layer responsibilities

- `lib/models/` — plain Dart value types with `fromJson`/`toJson`. No Flutter dependencies; safe to use from seed scripts.
- `lib/services/places_service.dart` — Google Places HTTP wrapper. **Used by the seed script, not the runtime client.** If you find yourself calling this from a screen, reconsider — you're about to leak cost.
- `lib/services/shop_repository.dart` — the only code path that touches Supabase tables. All reads/writes go through here.
- `lib/services/recommendation_service.dart` — pure filter + shuffle over an in-memory list. No network, no ML. Distance is Haversine, not geographic queries in Postgres, because the shop set is small (Hanoi-only MVP).
- `lib/core/tags.dart` — controlled tag vocabulary. The admin ingestion tool and the preferences screen must both use this list; new tags go here first.
- `lib/core/env.dart` — `.env` loader. Throws on missing keys rather than silently defaulting, to fail loudly in dev.

### Data model invariants

- `shops` is readable by any authenticated user; writes require the service role key. Never ship the service role key in the Flutter binary — it belongs only in `tools/` and the (future) admin web tool.
- A row in `profiles` is auto-created by the `on_auth_user_created` trigger in `0001_init.sql`. Client code should assume the profile row exists after sign-in and UPSERT preferences, not insert.
- Swipes are append-only. `saved_shops` is a materialized convenience table written alongside an `up` swipe; do not treat it as the source of truth for saves — `swipes` is.
- RLS restricts `swipes` / `saved_shops` / `profiles` to the owning user. Cross-user reads (e.g. future social features) will require new policies, not bypassing RLS.

### Hanoi-specific constraints

- Places API coverage is thin for alleyway cafés. The curated override layer (`tools/curated_hanoi.json` + future admin tool) is load-bearing, not optional.
- `shops.name_vi` holds the Vietnamese display name; `Shop.displayName` prefers it over `name`. Do not ASCII-fold Vietnamese names.
- Google opening hours are frequently wrong for Hanoi. "Open now" filtering should be a soft signal, not a hard exclude, or decks go empty.

## Git workflow

After every major change — completing a phase from the plan, finishing a feature, landing a non-trivial refactor — commit and push to GitHub. "Major" means something you'd want to roll back to if the next change breaks things; don't commit after every individual file edit.

This repo is connected to GitHub (`origin`, default branch `main`). The loop is `git add` → `git commit -m "…"` → `git push`. Ask before force-pushing or pushing to `main` directly once branch protection is in place.

## What NOT to do

- Don't add features outside the MVP scope in the plan file (reviews, social, ML, Android, partner portal) without discussing first — they are explicitly deferred.
- Don't scrape Instagram for ingestion. It violates Meta ToS and closes off the legal Graph API path later. Manual paste via the admin tool is the sanctioned ingestion path.
- Don't call Google Places from the Flutter client at runtime — all Places calls happen in `tools/` scripts against the service role key.
- Don't introduce new state management libraries. The plan commits to Riverpod; mixing Bloc or Provider fragments the codebase.
