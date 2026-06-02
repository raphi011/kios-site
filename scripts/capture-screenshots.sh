#!/usr/bin/env bash
#
# capture-screenshots.sh — regenerate the marketing screenshots (light + dark)
# from the Kios iOS simulator and drop them into static/site-assets/.
#
# Produces 6 opaque, edge-to-edge WebP captures at 900px wide:
#   home-{light,dark}.webp  reader-{light,dark}.webp  stats-{light,dark}.webp
# The site frames them with a pure-CSS bezel (.screen-frame) and swaps
# light/dark via <picture> + prefers-color-scheme, so the captures must be
# plain solid rectangles — no baked device frame, no alpha.
#
# ── Requirements ────────────────────────────────────────────────────────────
#   • A booted iPhone simulator with Kios installed (the newest iPhone 17 Pro
#     is auto-detected; override with KIOS_UDID=...).
#       cd ../kios && make run-ios
#   • axe       (brew install cameroncooke/axe/axe)  — drives the app by the
#               accessibility identifiers added in the Kios app:
#               home.continueReading, home.statistics, stats.range.year.
#   • cwebp     (brew install webp)                  — PNG → WebP.
#
# ── One-time prerequisite: the reader must be past pace-learning ────────────
#   The reader footer shows "Learning your reading speed …" until the
#   continue-reading book has 4 persisted pace samples; only then does it show
#   the clean "Nm left in book" estimate we want in the shot. The estimator
#   rejects fast/scripted page turns, so this is a manual, one-time step per
#   simulator (the samples persist across relaunches and reinstalls):
#     1. Open the continue-reading book on the sim.
#     2. Turn ~6 pages at a natural pace (>2s between turns), staying within
#        one chapter (chapter-boundary turns are dropped).
#     3. Background the app (Home button) to flush the samples to disk.
#     4. Reopen — the footer should read "Nm left in book". Done.
#   (A wiped/reset sim needs this again. A DEBUG seed flag in the app could
#   automate it; deferred — see the marketing-site spec, Component 3.)
#
# ── Assumptions ─────────────────────────────────────────────────────────────
#   • The app's Settings → Appearance is "System" (the default), so
#     `simctl ui … appearance` drives both the app chrome and the reader
#     day/night theme.
#   • Language is English (set the sim's language to English if not).
#
set -euo pipefail

BUNDLE_ID="com.raphi011.kios"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSET_DIR="$SCRIPT_DIR/../static/site-assets"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# ── Resolve the simulator UDID ──────────────────────────────────────────────
UDID="${KIOS_UDID:-$(xcrun simctl list devices booted | grep -oE '[0-9A-F-]{36}' | head -1)}"
if [[ -z "$UDID" ]]; then
  echo "error: no booted simulator found. Boot one first: (cd ../kios && make run-ios)" >&2
  exit 1
fi
echo "▸ simulator: $UDID"

axe()    { command axe "$@" --udid "$UDID" >/dev/null 2>&1; }
shot()   { xcrun simctl io "$UDID" screenshot "$1" >/dev/null; }
relaunch() {
  xcrun simctl terminate "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
  xcrun simctl launch "$UDID" "$BUNDLE_ID" >/dev/null
  sleep 2
}

# Clean App-Store-style status bar (9:41, full battery + signal).
xcrun simctl status_bar "$UDID" override \
  --time "9:41" --batteryState charged --batteryLevel 100 \
  --cellularBars 4 --dataNetwork wifi --wifiMode active --wifiBars 3

for THEME in light dark; do
  echo "▸ capturing $THEME …"
  xcrun simctl ui "$UDID" appearance "$THEME" >/dev/null

  # Home (Today)
  relaunch
  shot "$TMP_DIR/home-$THEME.png"

  # Reader — opens chrome-hidden on a cold launch → clean immersive page.
  axe tap --id "home.continueReading"
  sleep 5
  shot "$TMP_DIR/reader-$THEME.png"

  # Statistics → Year (the reading-days heatmap).
  relaunch
  axe tap --id "home.statistics"; sleep 2
  axe tap --id "stats.range.year"; sleep 2
  shot "$TMP_DIR/stats-$THEME.png"
done

# ── PNG → WebP (900px wide, opaque), into static/site-assets/ ───────────────
echo "▸ converting to WebP → $ASSET_DIR"
for name in home-light home-dark reader-light reader-dark stats-light stats-dark; do
  cwebp -q 82 -resize 900 0 -noalpha "$TMP_DIR/$name.png" -o "$ASSET_DIR/$name.webp" >/dev/null 2>&1
  echo "  $name.webp"
done

echo "✓ done. Review with: cd $SCRIPT_DIR/.. && hugo server"
