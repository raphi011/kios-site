# /docs page — sync servers & setup

**Date:** 2026-06-04 · **Status:** approved

## Goal

A single public page at `/docs/` documenting which self-hosted ebook servers Kios
syncs with and how to configure each, in the site's editorial visual language.
Today the site only says "KOReader Sync and Kobo Sync" — the app actually speaks
five protocols against ~11 servers.

## Decisions (brainstormed 2026-06-04)

- **Server scope:** all ~11 servers, with honesty badges (`Verified` / `Untested`).
- **IA:** one page at `/docs/`, anchor-linked sections. No subpages, no sidebar.
- **Extra content:** "How sync works" + "Troubleshooting". No import guide, no privacy section.
- **Approach:** editorial page extending the landing-page design system (approach A).

## Content source of truth

Hand-condensed at write time from the app repo (`~/Git/kios`):

- `docs/feature/sync.md` — plain-language sync behavior
- `docs/technical/sync-backends/README.md` — capability matrix (verified 2026-06-02)
- `docs/technical/sync-backends/<server>.md` + `kosync.md` / `kobo.md` — per-server setup values and quirks

Static copy, manually maintained. When the app matrix changes, this page is updated by hand.

## Page structure (top → bottom)

1. **Nav** — shared header; `Docs` link added to nav + footer of all pages.
2. **Head** — eyebrow `Documentation.`, display heading, short lede, slim anchor TOC:
   *How sync works · Servers · KOReader sync · Kobo sync · OPDS · Troubleshooting*.
3. **How sync works** — 3–4 short paragraphs: position-only sync; pushes on
   background/close/foreground (never per page turn); the cross-device
   "Another device is in …" prompt; Continue/Stay semantics.
4. **Server matrix** — 4 public columns: Server · Browse & download · Progress sync · Status.

   | Server | Browse & download | Progress sync | Status |
   |---|---|---|---|
   | Grimmory (BookLore fork) | OPDS 1.2 | kosync, Kobo | Verified |
   | Calibre-Web-Automated | OPDS 1.2 | kosync, Kobo | Verified |
   | Komga | OPDS 1.2 + 2.0 | kosync, OPDS progression | Verified |
   | BookLore | OPDS 1.2 | kosync, Kobo | Untested |
   | Calibre-Web (upstream) | OPDS 1.2 | Kobo | Untested |
   | Calibre content server | OPDS 1.2 | — browse only | Untested |
   | COPS | OPDS 1.2 | — browse only | Untested |
   | Kavita | OPDS 1.2 | kosync (v0.8.7+) | Untested |
   | Stump | OPDS 1.2 + 2.0 | kosync (off by default), OPDS progression | Untested |
   | Storyteller | OPDS 1.2 | — browse only¹ | Untested |
   | Ubooquity | OPDS 1.2 | — browse only¹ | Untested |

   ¹ Progress syncs only through the server's own proprietary API — not reachable by a
   standards-based client.

   Badge copy: **Verified** = "run against Kios, works"; **Untested** = "server
   implements the protocol; not yet exercised against Kios". Rows carry `id`
   anchors (`#komga` …). Nuances live in cell text, not a footnote forest (e.g.
   Stump's Kobo endpoints are catalog-only and so are omitted from its progress cell).
5. **Per-protocol setup** — three blocks. Each: intro sentence, mono field rows
   ("what you enter in Kios"), then per-server `<details>` quirks (`.faq-item` style).
   - **KOReader sync (kosync):** fields = Server URL (**full** base incl. sub-path),
     Username, Password, auth mode (HTTP Basic vs MD5). Quirks: CWA base `…/kosync`
     + HTTP Basic; Grimmory base `…/api/koreader` + MD5; Komga/Kavita = API key as
     username; Stump needs `ENABLE_KOREADER_SYNC`; Kavita needs library rescan
     (pre-v0.8.7 libraries).
   - **Kobo sync:** token-in-URL model; per-server token generation (CWA/Calibre-Web
     profile page → Kobo sync token; Grimmory; BookLore). Exact values from `kobo.md`
     and per-server docs.
   - **OPDS catalogs:** catalog URL + optional HTTP Basic; progression sync is
     automatic where offered (Komga; Stump experimental).
6. **Troubleshooting** — `<details>` items: pushes fail/404 → wrong kosync base URL;
   Kavita: no matches until forced rescan; Kobo whole-book % differs across devices
   (firmware quirk, chapter is correct); "no progress yet" on first open is normal.
7. **Pre-footer rule** — one line: "Stuck? Ask on Discord." + existing footer.

## Technical implementation

- **Layout honesty fix:** `layouts/_default/single.html` → `layouts/_default/privacy.html`;
  `content/privacy.md` gains `layout: privacy`. `/privacy/` output must stay identical.
- **New page:** `content/docs.md` (frontmatter only: title, description, `layout: docs`)
  + hardcoded `layouts/_default/docs.html`.
- **Partials extraction:** nav + footer are copy-pasted per layout and all need a new
  `Docs` link → extract `layouts/partials/nav.html` + `layouts/partials/footer.html`,
  consumed by index/privacy/docs layouts. Nav partial takes the link-prefix difference
  (`#features` on home vs `/#features` elsewhere) into account.
- **CSS:** ~100–120 lines appended to `assets/site.css`, existing tokens only:
  `.docs-toc` (anchor strip), `.docs-table` (full-width, `overflow-x:auto` wrapper,
  `scroll-margin-top` on row anchors), `.badge` (`--accent-soft`/`--accent` for
  Verified, `--surface-alt`/`--muted` for Untested), `.field-row` (mono key/value).
  Expandables reuse `.faq-item` unchanged.
- **SEO:** title "Sync servers & setup — Kios docs"; description naming
  KOReader/Kobo/OPDS + major servers. Same head partials (fonts self-hosted,
  Umami) as other pages.
- **No JS.** No scroll-spy, no search, no per-server pages, no automated sync of the
  matrix from the app repo.

## Verification

- `hugo --minify --gc` builds clean.
- `/privacy/` HTML diff vs pre-refactor output: identical (modulo whitespace).
- Both color schemes (`prefers-color-scheme`) and ~375 px viewport: matrix scrolls
  horizontally, nothing overflows.
- All TOC + matrix row anchors resolve; nav/footer `Docs` link present on all three pages.

## Out of scope

Per-server walkthrough pages, JS behaviors, importing-books guide, privacy addendum
(tracked separately), automated matrix generation.
