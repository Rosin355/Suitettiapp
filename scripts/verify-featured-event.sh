#!/usr/bin/env bash
#
# End-to-end verification for the dynamic featured-event banner.
#
# Hits the PUBLIC sync-editorial endpoint — no credentials, no privileges, no
# simulator. Safe to run from anywhere, by anyone, on any platform.
#
# Usage:
#   scripts/verify-featured-event.sh
#
# What it tells you, in order:
#   1. whether the `is_home_featured` migration has reached production
#   2. which event (if any) is currently promoted
#   3. what the iOS/Android apps will therefore render
#
# Exit codes: 0 = contract healthy, 1 = migration not applied, 2 = fetch failed.

set -uo pipefail

ENDPOINT="${SYNC_ENDPOINT:-https://kbswgeliohnpwopzzzpc.supabase.co/functions/v1/sync-editorial}"
TMP="$(mktemp -t sync-editorial)"
trap 'rm -f "$TMP"' EXIT

printf '→ GET %s\n\n' "$ENDPOINT"
if ! curl -fsS "$ENDPOINT" -o "$TMP"; then
  echo "✗ fetch failed — endpoint unreachable or returned an error"
  exit 2
fi

python3 - "$TMP" <<'PY'
import json, sys

with open(sys.argv[1]) as fh:
    payload = json.load(fh)

events = payload.get("events", [])
articles = payload.get("articles", [])
documents = payload.get("documents", [])

print(f"payload: {len(articles)} articles, {len(events)} events, {len(documents)} documents")

if not events:
    print("✗ no events in payload — cannot assess the contract")
    sys.exit(2)

# 1. Is the column live? The function spreads select("*") from mobile_events_public,
#    so the key is present on every event as soon as the view exposes it.
with_key = [e for e in events if "is_home_featured" in e]

print()
if not with_key:
    print("✗ `is_home_featured` is ABSENT from the payload")
    print("  → the migration has NOT been applied to production yet.")
    print("  → apply supabase/migrations/20260818120000_expose_home_featured_to_mobile.sql")
    print("    in the ditelo-on-air repo, then re-run this script.")
    print()
    print("  Apps are unaffected in this state: every event decodes as")
    print("  isFeatured = false and no banner renders.")
    sys.exit(1)

if len(with_key) != len(events):
    print(f"⚠ `is_home_featured` present on only {len(with_key)}/{len(events)} events — unexpected")
else:
    print(f"✓ `is_home_featured` present on all {len(events)} events — migration is live")

# 2. Type sanity: anything other than a real boolean means something re-shaped the view.
bad = [e for e in with_key if not isinstance(e.get("is_home_featured"), bool)]
if bad:
    print(f"⚠ {len(bad)} event(s) have a non-boolean is_home_featured "
          f"(e.g. {bad[0].get('titolo')!r} → {bad[0].get('is_home_featured')!r})")
    print("  Clients tolerate this (decodes to false) but the column type is wrong.")
else:
    print("✓ all values are proper booleans")

# 3. Who is promoted?
flagged = [e for e in events if e.get("is_home_featured") is True]
print()
if not flagged:
    print("• nothing is currently featured → apps render NO banner")
    print("  (this is the expected state after un-featuring)")
else:
    print(f"• {len(flagged)} event(s) flagged featured:")
    for e in flagged:
        print(f"    - {e.get('titolo')}")
        print(f"      date={e.get('data_evento')}  luogo={e.get('luogo')}")
        print(f"      image={'yes' if e.get('immagine_url') else 'no (brand fallback)'}")
        print(f"      updated_at={e.get('updated_at')}")

    if len(flagged) > 1:
        print()
        print("  ⚠ more than one event is featured. The admin toggle is exclusive, so")
        print("    this came from a direct DB edit. Clients will NOT crash: they resolve")
        print("    deterministically (upcoming → nearest date → newest updated_at → id)")
        print("    and log a warning. Winner the apps will pick:")

        from datetime import datetime, timezone

        def parse_date(value):
            try:
                return datetime.strptime(value, "%Y-%m-%d").replace(tzinfo=timezone.utc)
            except (TypeError, ValueError):
                return None

        def parse_updated(value):
            try:
                return datetime.fromisoformat((value or "").replace("Z", "+00:00"))
            except ValueError:
                return datetime.min.replace(tzinfo=timezone.utc)

        today = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)

        def sort_key(e):
            d = parse_date(e.get("data_evento"))
            upcoming = d is not None and d >= today
            # mirrors EventStore.resolveFeatured ordering
            return (
                0 if upcoming else 1,
                (d or datetime.max.replace(tzinfo=timezone.utc)).timestamp() if upcoming
                else -((d or datetime.min.replace(tzinfo=timezone.utc)).timestamp()),
                -parse_updated(e.get("updated_at")).timestamp(),
                str(e.get("id")),
            )

        winner = sorted(flagged, key=sort_key)[0]
        print(f"      → {winner.get('titolo')}")

print()
print("Expected app behaviour with this payload:")
if flagged:
    print("  iOS/Android Home shows the featured-event banner for the event above,")
    print("  tapping it opens the NATIVE event detail, and the same event is filtered")
    print("  out of the 'Prossimi eventi' preview.")
else:
    print("  iOS/Android Home shows no banner at all (no placeholder, no empty space).")
PY

status=$?
echo
if [ $status -eq 0 ]; then
  echo "✓ contract healthy"
fi
exit $status
