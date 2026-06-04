# /docs Sync-Servers Page Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship `/docs/` — a single editorial page documenting which self-hosted ebook servers Kios syncs with and exactly how to configure each.

**Architecture:** Hugo static site; the page is a hardcoded layout (`layouts/_default/docs.html`) routed by a frontmatter-only `content/docs.md`, in the same pattern as the privacy page. Nav/footer get extracted into partials first (they gain a Docs link and are currently copy-pasted), and `single.html` is renamed to an explicit `privacy.html` so the layout system stops lying. All styling appends to `assets/site.css` using existing design tokens only — no JS.

**Tech Stack:** Hugo (hugomods/hugo:exts), hand-written HTML/CSS, no framework.

**Spec:** `docs/superpowers/specs/2026-06-04-docs-page-design.md`

**Verification model:** no test framework exists (static site). Every task verifies with `hugo --minify --gc` + exact `grep`/`diff` assertions on `public/` output. Tasks 1–2 are refactors with a **byte-identical output** requirement.

---

## File structure

| File | Responsibility |
|---|---|
| `layouts/partials/nav.html` | NEW — shared header; `.IsHome`-aware link prefixes |
| `layouts/partials/footer.html` | NEW — shared footer; `.IsHome`-aware link prefixes |
| `layouts/_default/privacy.html` | RENAMED from `single.html`; uses partials |
| `layouts/_default/docs.html` | NEW — the entire /docs page |
| `layouts/index.html` | MODIFIED — uses partials |
| `content/docs.md` | NEW — route stub (`layout: docs`) |
| `content/privacy.md` | MODIFIED — gains `layout: privacy` |
| `assets/site.css` | MODIFIED — `/* ── Docs page ── */` block appended |
| `CLAUDE.md` | MODIFIED — architecture notes + matrix source-of-truth |

Content facts (matrix rows, URLs, auth modes) were extracted 2026-06-04 from the app repo `~/Git/kios/docs/technical/sync-backends/` (verified there 2026-06-02) and from the app UI source (`KOSyncSetupView.swift`, `AddSourceView.swift`). They are reproduced verbatim in the tasks below — the executor does NOT need to re-derive them.

---

### Task 0: Commit pending working-tree changes

The tree has uncommitted font self-hosting work + a new CLAUDE.md from earlier in this session. Commit them so plan tasks produce clean diffs.

**Files:**
- Existing modifications: `assets/site.css`, `static/fonts/*.woff2` (4 files), `CLAUDE.md`

- [ ] **Step 1: Verify what's pending**

Run: `git status --short`
Expected: `M assets/site.css`, `?? CLAUDE.md`, `?? static/fonts/`

- [ ] **Step 2: Commit fonts**

```bash
git add assets/site.css static/fonts
git commit -m "feat(fonts): self-host Newsreader/Geist/Geist Mono, drop Google Fonts

Replaces five fonts.googleapis.com @imports (two of them unused: EB Garamond,
IBM Plex Serif) with four self-hosted variable woff2 files (latin subset).
No more third-party requests on page load."
```

- [ ] **Step 3: Commit CLAUDE.md**

```bash
git add CLAUDE.md
git commit -m "docs: add CLAUDE.md with build/deploy/layout notes"
```

---

### Task 1: Extract nav + footer partials (byte-identical refactor)

**Files:**
- Create: `layouts/partials/nav.html`
- Create: `layouts/partials/footer.html`
- Modify: `layouts/index.html` (nav lines 17–29, footer lines 200–235)
- Modify: `layouts/_default/single.html` (nav lines 17–29, footer lines 89–124)

- [ ] **Step 1: Capture baseline output**

```bash
hugo --minify --gc
cp public/index.html /tmp/index-before.html
cp public/privacy/index.html /tmp/privacy-before.html
```

- [ ] **Step 2: Create `layouts/partials/nav.html`**

The only differences between the two existing nav blocks: home page has `class="nav"` + brand href `#top` + bare `#features`/`#faq`; privacy has `class="nav scrolled"` + brand href `/` + `/#features`/`/#faq`. `.IsHome` captures all three.

```html
<header class="nav{{ if not .IsHome }} scrolled{{ end }}" id="nav">
  <div class="nav-inner">
    <a class="brand" href="{{ if .IsHome }}#top{{ else }}/{{ end }}" aria-label="Kios home">
      <img src="/site-assets/app-icon.png" alt="" />
      <span class="word">Kios<span class="reddot">.</span></span>
    </a>
    <nav class="nav-links">
      <a href="{{ if not .IsHome }}/{{ end }}#features" class="hide-sm">Features</a>
      <a href="{{ if not .IsHome }}/{{ end }}#faq" class="hide-sm">FAQ</a>
      <a class="btn btn-primary" href="https://testflight.apple.com/join/fzdZFbtM" target="_blank" rel="noopener">Join the beta</a>
    </nav>
  </div>
</header>
```

- [ ] **Step 3: Create `layouts/partials/footer.html`**

Identical between pages except the `#features`/`#faq` prefixes. Copy the footer block from `layouts/index.html:200-235` verbatim, then apply ONLY these substitutions: `href="#features"` → `href="{{ if not .IsHome }}/{{ end }}#features"` (3×), `href="#faq"` → `href="{{ if not .IsHome }}/{{ end }}#faq"` (1×). Keep the Discord SVG path bytes untouched.

```html
<footer class="footer">
  <div class="wrap">
    <div class="footer-grid">
      <div>
        <div class="brand">
          <img src="/site-assets/app-icon.png" alt="" />
          <span class="word">Kios<span class="reddot">.</span></span>
        </div>
        <p class="footer-tag">A reader for the slow web.</p>
      </div>
      <div class="footer-col">
        <h4>App</h4>
        <ul>
          <li><a href="{{ if not .IsHome }}/{{ end }}#features">Reading</a></li>
          <li><a href="{{ if not .IsHome }}/{{ end }}#features">Library</a></li>
          <li><a href="{{ if not .IsHome }}/{{ end }}#features">Statistics</a></li>
        </ul>
      </div>
      <div class="footer-col">
        <h4>Beta &amp; legal</h4>
        <ul>
          <li><a href="https://testflight.apple.com/join/fzdZFbtM" target="_blank" rel="noopener">TestFlight beta</a></li>
          <li><a href="{{ if not .IsHome }}/{{ end }}#faq">FAQ</a></li>
          <li><a href="/privacy/">Privacy policy</a></li>
        </ul>
      </div>
    </div>
    <div class="footer-base">
      <span>© 2026 Kios · A reader for the slow web</span>
      <a class="discord-btn" href="https://discord.gg/spTFCkhP" target="_blank" rel="noopener">
        <svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M20.317 4.3698a19.7913 19.7913 0 0 0-4.8851-1.5152.0741.0741 0 0 0-.0785.0371c-.211.3753-.4447.8648-.6083 1.2495-1.8447-.2762-3.68-.2762-5.4868 0-.1636-.3933-.4058-.8742-.6177-1.2495a.077.077 0 0 0-.0785-.037 19.7363 19.7363 0 0 0-4.8852 1.515.0699.0699 0 0 0-.0321.0277C.5334 9.0458-.319 13.5799.0992 18.0578a.0824.0824 0 0 0 .0312.0561c2.0528 1.5076 4.0413 2.4228 5.9929 3.0294a.0777.0777 0 0 0 .0842-.0276c.4616-.6304.8731-1.2952 1.226-1.9942a.076.076 0 0 0-.0416-.1057c-.6528-.2476-1.2743-.5495-1.8722-.8923a.077.077 0 0 1-.0076-.1277c.1258-.0943.2517-.1923.3718-.2914a.0743.0743 0 0 1 .0776-.0105c3.9278 1.7933 8.18 1.7933 12.0614 0a.0739.0739 0 0 1 .0785.0095c.1202.099.246.1981.3728.2924a.077.077 0 0 1-.0066.1276 12.2986 12.2986 0 0 1-1.873.8914.0766.0766 0 0 0-.0407.1067c.3604.698.7719 1.3628 1.225 1.9932a.076.076 0 0 0 .0842.0286c1.961-.6067 3.9495-1.5219 6.0023-3.0294a.077.077 0 0 0 .0313-.0552c.5004-5.177-.8382-9.6739-3.5485-13.6604a.061.061 0 0 0-.0312-.0286zM8.02 15.3312c-1.1825 0-2.1569-1.0857-2.1569-2.419 0-1.3332.9555-2.4189 2.157-2.4189 1.2108 0 2.1757 1.0952 2.1568 2.419 0 1.3332-.9555 2.4189-2.1569 2.4189zm7.9748 0c-1.1825 0-2.1569-1.0857-2.1569-2.419 0-1.3332.9554-2.4189 2.1569-2.4189 1.2108 0 2.1757 1.0952 2.1568 2.419 0 1.3332-.946 2.4189-2.1568 2.4189Z"/></svg>
        Join our Discord
      </a>
    </div>
  </div>
</footer>
```

- [ ] **Step 4: Use the partials in both layouts**

In `layouts/index.html`: replace the `<!-- ── Nav … -->` comment + `<header …>…</header>` block (lines 16–29) with:

```html
  <!-- ── Nav ───────────────────────────────────────────── -->
  {{ partial "nav.html" . }}
```

Replace the `<!-- ── Footer … -->` comment + `<footer …>…</footer>` block (lines 199–235) with:

```html
  <!-- ── Footer ────────────────────────────────────────── -->
  {{ partial "footer.html" . }}
```

Keep `<a id="top"></a>` and the nav-scroll `<script>` in `index.html` — the script only exists on the home page (other pages hardcode `scrolled`).

Apply the same two replacements in `layouts/_default/single.html` (nav lines 16–29, footer lines 88–124).

- [ ] **Step 5: Verify byte-identical output**

```bash
hugo --minify --gc
diff /tmp/index-before.html public/index.html && diff /tmp/privacy-before.html public/privacy/index.html && echo IDENTICAL
```

Expected: `IDENTICAL` (no diff lines). If a diff appears, it must be whitespace-only inside tags; anything else means a substitution error — fix before committing.

- [ ] **Step 6: Commit**

```bash
git add layouts
git commit -m "refactor(layouts): extract shared nav + footer partials"
```

---

### Task 2: Rename `single.html` → explicit `privacy.html`

`_default/single.html` is a hardcoded privacy page, which would render at ANY new content page's route (the `/docs/` trap). Make it explicit.

**Files:**
- Rename: `layouts/_default/single.html` → `layouts/_default/privacy.html`
- Modify: `content/privacy.md`

- [ ] **Step 1: Rename the layout**

```bash
git mv layouts/_default/single.html layouts/_default/privacy.html
```

- [ ] **Step 2: Point privacy.md at it**

Replace the full frontmatter of `content/privacy.md` with:

```markdown
---
title: "Privacy Policy"
layout: privacy
---
```

- [ ] **Step 3: Verify /privacy/ output unchanged**

```bash
hugo --minify --gc
diff /tmp/privacy-before.html public/privacy/index.html && echo IDENTICAL
```

Expected: `IDENTICAL`.

- [ ] **Step 4: Commit**

```bash
git add -A layouts content/privacy.md
git commit -m "refactor(layouts): rename single.html to explicit privacy layout

_default/single.html was a hardcoded privacy page; any new content file
would have rendered it. Pages now opt in via layout: privacy."
```

---

### Task 3: Docs page CSS

**Files:**
- Modify: `assets/site.css` (append at end of file)

- [ ] **Step 1: Append the docs block to `assets/site.css`**

```css
/* ── Docs page ───────────────────────────────────────────── */
.docs { padding-block: clamp(48px, 7vw, 96px); }
.docs-head .display { font-size: clamp(2.4rem, 5vw, 4rem); margin-top: 14px; }
.docs-head .lede { margin-top: 22px; }

.docs-toc {
  display: flex; flex-wrap: wrap; gap: 10px 24px;
  margin-top: clamp(28px, 4vw, 44px);
  padding-block: 16px;
  border-block: 1px solid var(--rule);
  font-family: var(--mono); font-size: 0.74rem; letter-spacing: 0.1em; text-transform: uppercase;
}
.docs-toc a { color: var(--muted); transition: color 0.15s ease; }
.docs-toc a:hover { color: var(--accent); }

.docs-section { margin-top: clamp(48px, 7vw, 80px); scroll-margin-top: 84px; }
.docs-section h2 { font-size: clamp(1.6rem, 2.6vw, 2.2rem); letter-spacing: -0.02em; margin: 14px 0 18px; }
.docs-prose { max-width: 68ch; }
.docs-prose p { margin: 0 0 16px; color: var(--ink-soft); font-size: 1.06rem; line-height: 1.7; }
.docs-prose a { color: var(--accent); text-decoration: underline; text-underline-offset: 3px; }
.docs-fine { font-size: 0.92rem; color: var(--muted); }
.docs code {
  font-family: var(--mono); font-size: 0.88em;
  background: var(--surface-alt); box-shadow: inset 0 0 0 1px var(--rule-soft);
  padding: 2px 7px; border-radius: 6px; white-space: nowrap;
}

/* compatibility matrix */
.docs-table-wrap { overflow-x: auto; margin-block: 8px 16px; }
.docs-table { width: 100%; min-width: 640px; border-collapse: collapse; font-size: 0.97rem; }
.docs-table th {
  font-family: var(--mono); font-size: 0.7rem; letter-spacing: 0.1em; text-transform: uppercase;
  color: var(--muted); font-weight: 500; text-align: left;
  padding: 10px 16px 10px 0; border-bottom: 1px solid var(--rule-strong);
}
.docs-table td { padding: 13px 16px 13px 0; border-bottom: 1px solid var(--rule); color: var(--ink-soft); vertical-align: top; }
.docs-table td:first-child { color: var(--ink); font-weight: 600; white-space: nowrap; }
.docs-table tr { scroll-margin-top: 84px; }

/* status badges */
.badge {
  display: inline-block; padding: 4px 11px; border-radius: 999px;
  font-family: var(--mono); font-size: 0.68rem; letter-spacing: 0.09em; text-transform: uppercase;
  white-space: nowrap;
}
.badge-verified { background: var(--accent-soft); color: var(--accent); }
.badge-untested { background: var(--surface-alt); color: var(--muted); box-shadow: inset 0 0 0 1px var(--rule); }

/* "what you enter in Kios" rows */
.field-list { display: grid; gap: 8px; max-width: 68ch; margin-block: 20px 28px; }
.field-row {
  display: grid; grid-template-columns: clamp(110px, 18vw, 150px) 1fr; gap: 14px;
  padding: 11px 16px; background: var(--surface-alt); border-radius: 12px;
  font-size: 0.95rem; line-height: 1.5;
}
.field-key { font-family: var(--mono); font-size: 0.74rem; letter-spacing: 0.08em; text-transform: uppercase; color: var(--muted); align-self: center; }
.field-val { color: var(--ink-soft); }
.field-val em { color: var(--muted); }

/* docs expandables piggyback on .faq-item; allow paragraphs inside answers */
.docs .faq-answer p { margin: 0 0 12px; }
.docs .faq-answer p:last-child { margin-bottom: 0; }
.docs .faq-item summary { font-size: clamp(1.1rem, 1.7vw, 1.3rem); padding: 20px 4px; }

/* pre-footer help band */
.docs-prefooter { border-top: 1px solid var(--rule); padding-block: clamp(36px, 5vw, 60px); }
.docs-prefooter .wrap { display: flex; flex-wrap: wrap; align-items: center; justify-content: space-between; gap: 20px 40px; }
.docs-prefooter .lede { max-width: none; }
```

- [ ] **Step 2: Verify build still clean**

Run: `hugo --minify --gc`
Expected: ends with `Total in N ms`, no `ERROR` lines.

- [ ] **Step 3: Commit**

```bash
git add assets/site.css
git commit -m "feat(css): docs-page styles (toc, matrix, badges, field rows)"
```

---

### Task 4: Docs page shell — route, head, TOC, "How sync works"

**Files:**
- Create: `content/docs.md`
- Create: `layouts/_default/docs.html`

- [ ] **Step 1: Create `content/docs.md`**

```markdown
---
title: "Docs"
layout: docs
---
```

- [ ] **Step 2: Create `layouts/_default/docs.html`**

The four `<!-- TASK n: … -->` comments are insertion markers consumed by Tasks 5–8.

```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <meta name="color-scheme" content="light dark" />
  <title>Sync servers &amp; setup — Kios docs</title>
  <meta name="description" content="Which self-hosted ebook servers Kios syncs with — Komga, Calibre-Web, Grimmory, Kavita, Stump and more — and how to configure KOReader sync, Kobo sync and OPDS." />
  <link rel="icon" href="/site-assets/app-icon.png" />
  {{ $css := resources.Get "site.css" | minify | fingerprint }}
  <link rel="stylesheet" href="{{ $css.RelPermalink }}" integrity="{{ $css.Data.Integrity }}" />
  {{ partial "custom-head.html" . }}
</head>
<body>

  <!-- ── Nav ───────────────────────────────────────────── -->
  {{ partial "nav.html" . }}

  <!-- ── Docs ──────────────────────────────────────────── -->
  <main class="docs">
    <div class="wrap">

      <div class="docs-head">
        <p class="eyebrow">Documentation<span class="dot">.</span></p>
        <h1 class="display">Sync, with your<br>own server<span class="reddot">.</span></h1>
        <p class="lede" style="max-width:46ch;">Kios keeps your reading position in step with the library server you already run — over KOReader sync, Kobo sync or OPDS. Here's what works, and exactly what to type in.</p>
      </div>

      <nav class="docs-toc" aria-label="On this page">
        <a href="#how-it-works">How sync works</a>
        <a href="#servers">Servers</a>
        <a href="#koreader-sync">KOReader sync</a>
        <a href="#kobo-sync">Kobo sync</a>
        <a href="#opds">OPDS</a>
        <a href="#troubleshooting">Troubleshooting</a>
      </nav>

      <!-- ── How sync works ────────────────────────────────── -->
      <section class="docs-section" id="how-it-works">
        <p class="eyebrow">Behaviour<span class="dot">.</span></p>
        <h2>How sync works</h2>
        <div class="docs-prose">
          <p>Kios syncs your <em>reading position</em> — one position per book, nothing more. Highlights, notes and statistics stay on your device.</p>
          <p>Your position is saved locally on every page turn, but it's only sent to your server when you background the app, close a book, or return to the app with a push still pending. Page turns never touch the network.</p>
          <p>When you open a book, Kios asks the server in the background whether another device has read further. If it has — a different chapter, or meaningfully further in the same one — you'll see <em>“Another device is in ‘Chapter 12’ — switch?”</em> with <strong>Continue</strong> and <strong>Stay here</strong>. Tiny differences are applied silently, and if you've already started reading, the prompt stays out of your way.</p>
        </div>
      </section>

      <!-- TASK 5: servers section -->

      <!-- TASK 6: koreader-sync section -->

      <!-- TASK 7: kobo-sync + opds sections -->

      <!-- TASK 8: troubleshooting section -->

    </div>
  </main>

  <!-- TASK 8: pre-footer band -->

  <!-- ── Footer ────────────────────────────────────────── -->
  {{ partial "footer.html" . }}

</body>
</html>
```

- [ ] **Step 3: Verify the route renders with the docs layout**

```bash
hugo --minify --gc
grep -c "Sync, with your" public/docs/index.html
grep -c "docs-toc" public/docs/index.html
```

Expected: `1` and `1`. (If `public/docs/index.html` contains "Privacy policy", the layout didn't resolve — check the `layout: docs` frontmatter.)

- [ ] **Step 4: Commit**

```bash
git add content/docs.md layouts/_default/docs.html
git commit -m "feat(docs): /docs page shell — head, toc, how-sync-works"
```

---

### Task 5: Server compatibility matrix

**Files:**
- Modify: `layouts/_default/docs.html` (replace the `<!-- TASK 5: servers section -->` marker)

- [ ] **Step 1: Replace the marker with the section**

Facts source: app repo `sync-backends/README.md` capability matrix (2026-06-02). Komga's Kobo support and Stump's catalog-only Kobo are deliberately folded into prose, not the table.

```html
      <!-- ── Servers ───────────────────────────────────────── -->
      <section class="docs-section" id="servers">
        <p class="eyebrow">Compatibility<span class="dot">.</span></p>
        <h2>Servers</h2>
        <div class="docs-prose">
          <p><span class="badge badge-verified">Verified</span> means we've run Kios against the server and sync works. <span class="badge badge-untested">Untested</span> means the server implements a protocol Kios speaks, but the pair hasn't been exercised yet — reports very welcome on <a href="https://discord.gg/spTFCkhP" target="_blank" rel="noopener">Discord</a>.</p>
        </div>
        <div class="docs-table-wrap">
          <table class="docs-table">
            <thead>
              <tr><th>Server</th><th>Browse &amp; download</th><th>Progress sync</th><th>Status</th></tr>
            </thead>
            <tbody>
              <tr id="grimmory"><td>Grimmory</td><td>OPDS 1.2</td><td>KOReader sync · Kobo sync</td><td><span class="badge badge-verified">Verified</span></td></tr>
              <tr id="cwa"><td>Calibre-Web-Automated</td><td>OPDS 1.2</td><td>KOReader sync · Kobo sync</td><td><span class="badge badge-verified">Verified</span></td></tr>
              <tr id="komga"><td>Komga</td><td>OPDS 1.2 + 2.0</td><td>KOReader sync · OPDS progression</td><td><span class="badge badge-verified">Verified</span></td></tr>
              <tr id="booklore"><td>BookLore</td><td>OPDS 1.2</td><td>KOReader sync · Kobo sync</td><td><span class="badge badge-untested">Untested</span></td></tr>
              <tr id="calibre-web"><td>Calibre-Web</td><td>OPDS 1.2</td><td>Kobo sync</td><td><span class="badge badge-untested">Untested</span></td></tr>
              <tr id="kavita"><td>Kavita</td><td>OPDS 1.2</td><td>KOReader sync (v0.8.7+)</td><td><span class="badge badge-untested">Untested</span></td></tr>
              <tr id="stump"><td>Stump</td><td>OPDS 1.2 + 2.0</td><td>KOReader sync (off by default) · OPDS progression</td><td><span class="badge badge-untested">Untested</span></td></tr>
              <tr id="calibre"><td>Calibre content server</td><td>OPDS 1.2</td><td>— browse only</td><td><span class="badge badge-untested">Untested</span></td></tr>
              <tr id="cops"><td>COPS</td><td>OPDS 1.2</td><td>— browse only</td><td><span class="badge badge-untested">Untested</span></td></tr>
              <tr id="storyteller"><td>Storyteller</td><td>OPDS 1.2</td><td>— browse only</td><td><span class="badge badge-untested">Untested</span></td></tr>
              <tr id="ubooquity"><td>Ubooquity</td><td>OPDS 1.2</td><td>— browse only</td><td><span class="badge badge-untested">Untested</span></td></tr>
            </tbody>
          </table>
        </div>
        <div class="docs-prose">
          <p class="docs-fine">Grimmory is a fork of BookLore — their protocol surfaces match, so BookLore should behave identically. Storyteller and Ubooquity sync position only through their own proprietary APIs, which standards-based clients can't reach — browsing still works. Stump's Kobo endpoints deliver books but never sync position; use its OPDS progression or KOReader sync instead.</p>
        </div>
      </section>
```

- [ ] **Step 2: Verify**

```bash
hugo --minify --gc
grep -o 'badge-verified' public/docs/index.html | wc -l
grep -o '<tr id="' public/docs/index.html | wc -l
```

Expected: `4` (3 table badges + 1 legend) and `11`.

- [ ] **Step 3: Commit**

```bash
git add layouts/_default/docs.html
git commit -m "content(docs): server compatibility matrix with status badges"
```

---

### Task 6: KOReader sync setup section

**Files:**
- Modify: `layouts/_default/docs.html` (replace the `<!-- TASK 6: koreader-sync section -->` marker)

- [ ] **Step 1: Replace the marker with the section**

Facts: `kosync.md` (base-URL table, auth axes), `komga.md`, `kavita.md`, `stump.md`, `grimmory.md`; field names/labels from `KOSyncSetupView.swift` (Server URL / Username / Password / Auth method: "HTTP Basic" | "KOReader headers"); settings location from `SettingsView.swift` (Progress sync section).

```html
      <!-- ── KOReader sync ─────────────────────────────────── -->
      <section class="docs-section" id="koreader-sync">
        <p class="eyebrow">Setup<span class="dot">.</span></p>
        <h2>KOReader sync</h2>
        <div class="docs-prose">
          <p>The most widely implemented progress protocol — and Kios's global fallback for any book that isn't tied to a Kobo or OPDS source. Configure it in <strong>Settings → Progress sync</strong>.</p>
          <p>One rule matters more than the rest: <strong>enter the full sync URL, including the server's sub-path.</strong> Kios appends only the protocol's own routes — it never guesses a server-specific prefix.</p>
        </div>
        <div class="field-list">
          <div class="field-row"><span class="field-key">Server URL</span><span class="field-val">the full sync base — exact value per server below</span></div>
          <div class="field-row"><span class="field-key">Username</span><span class="field-val">account name <em>or API key, depending on the server</em></span></div>
          <div class="field-row"><span class="field-key">Password</span><span class="field-val">account password <em>(some servers ignore it — type anything)</em></span></div>
          <div class="field-row"><span class="field-key">Auth method</span><span class="field-val">HTTP Basic <em>or</em> KOReader headers — per server below</span></div>
        </div>
        <div class="faq-list">
          <details class="faq-item">
            <summary>Calibre-Web-Automated<span class="plus"></span></summary>
            <div class="faq-answer"><p>Server URL <code>https://your-server:8083/kosync</code> · auth method <strong>HTTP Basic</strong> · your normal CWA username and password.</p></div>
          </details>
          <details class="faq-item">
            <summary>Grimmory / BookLore<span class="plus"></span></summary>
            <div class="faq-answer"><p>Server URL <code>https://your-server:6062/api/koreader</code> · auth method <strong>KOReader headers</strong>.</p><p>Use the dedicated KOReader sync user you create in the server's settings — it's separate from your main login. Position only matches books that were downloaded through the server's own catalog.</p></div>
          </details>
          <details class="faq-item">
            <summary>Komga<span class="plus"></span></summary>
            <div class="faq-answer"><p>Server URL <code>https://your-server:25600/koreader</code> · auth method <strong>KOReader headers</strong> · username = a Komga <strong>API key</strong> (generate one in your account settings) · password is ignored — type anything.</p><p>Enable <em>“Compute hash for KOReader”</em> on the library and rescan once so books get matchable hashes.</p></div>
          </details>
          <details class="faq-item">
            <summary>Kavita<span class="plus"></span></summary>
            <div class="faq-answer"><p>Server URL <code>https://your-server:5000/api/koreader/your-api-key</code> — the API key rides in the URL; copy it from your Kavita user settings.</p><p>Needs Kavita <strong>v0.8.7</strong> or newer. Libraries created on older versions need a one-time forced scan so books get matching hashes.</p></div>
          </details>
          <details class="faq-item">
            <summary>Stump<span class="plus"></span></summary>
            <div class="faq-answer"><p>Server URL <code>https://your-server:10801/koreader/your-api-key</code>.</p><p>KOReader sync is <strong>off by default</strong>: the server needs <code>ENABLE_KOREADER_SYNC=true</code> and matching user permissions, and the library needs KOReader-compatible hashes enabled (then rescan).</p></div>
          </details>
          <details class="faq-item">
            <summary>koreader-sync-server (official)<span class="plus"></span></summary>
            <div class="faq-answer"><p>Server URL <code>https://your-server</code> — its routes live at the root · auth method <strong>KOReader headers</strong> · the username and password you registered with.</p></div>
          </details>
        </div>
      </section>
```

- [ ] **Step 2: Verify**

```bash
hugo --minify --gc
grep -o 'koreader-sync' public/docs/index.html | wc -l
grep -c 'kosync</code>' public/docs/index.html
```

Expected: `≥2` (TOC link + section id) and `1`.

- [ ] **Step 3: Commit**

```bash
git add layouts/_default/docs.html
git commit -m "content(docs): KOReader sync setup with per-server values"
```

---

### Task 7: Kobo sync + OPDS sections

**Files:**
- Modify: `layouts/_default/docs.html` (replace the `<!-- TASK 7: kobo-sync + opds sections -->` marker)

- [ ] **Step 1: Replace the marker with both sections**

Facts: `kobo.md`, `calibre-web.md`, `grimmory.md` (`/api/kobo/<token>` incl. `/api` prefix), `komga.md`; the single-field Kobo form and the optional both-or-neither OPDS auth from `AddSourceView.swift`; OPDS catalog paths from each per-server doc.

```html
      <!-- ── Kobo sync ─────────────────────────────────────── -->
      <section class="docs-section" id="kobo-sync">
        <p class="eyebrow">Setup<span class="dot">.</span></p>
        <h2>Kobo sync</h2>
        <div class="docs-prose">
          <p>The same protocol a Kobo e-reader speaks — the server keeps Kios, your Kobo and its own web reader in step: catalog, covers and position. Add it in <strong>Settings → Library sync → Add source</strong>, kind <strong>Kobo sync</strong>.</p>
          <p>There's a single field beyond the display name: the personal sync URL your server generates for you, token included.</p>
        </div>
        <div class="field-list">
          <div class="field-row"><span class="field-key">Display name</span><span class="field-val">anything — Kios suggests one from the host</span></div>
          <div class="field-row"><span class="field-key">Kobo sync URL</span><span class="field-val">the full per-user URL, token included — per server below</span></div>
        </div>
        <div class="faq-list">
          <details class="faq-item">
            <summary>Calibre-Web-Automated / Calibre-Web<span class="plus"></span></summary>
            <div class="faq-answer"><p>Enable Kobo sync in the admin feature settings, then generate your token on your user profile page. The URL looks like <code>https://your-server:8083/kobo/your-token</code>.</p></div>
          </details>
          <details class="faq-item">
            <summary>Grimmory / BookLore<span class="plus"></span></summary>
            <div class="faq-answer"><p>Each user gets a sync token in their settings. Mind the <code>/api</code> prefix: <code>https://your-server:6062/api/kobo/your-token</code>.</p></div>
          </details>
          <details class="faq-item">
            <summary>Komga<span class="plus"></span></summary>
            <div class="faq-answer"><p><code>https://your-server:25600/kobo/your-api-key</code> with a Komga API key. Catalog and download answer correctly in our wire tests, but Kobo <em>position</em> sync against Komga is untested — KOReader sync and OPDS progression are Komga's proven routes.</p></div>
          </details>
        </div>
      </section>

      <!-- ── OPDS ──────────────────────────────────────────── -->
      <section class="docs-section" id="opds">
        <p class="eyebrow">Setup<span class="dot">.</span></p>
        <h2>OPDS catalogs</h2>
        <div class="docs-prose">
          <p>Every server on this page publishes an OPDS catalog — browse your library and download books straight into Kios. Add it in <strong>Settings → Library sync → Add source</strong>, kind <strong>OPDS</strong>. Username and password are optional: fill both, or neither.</p>
          <p>Where the catalog also advertises a Readium <em>progression</em> endpoint — Komga today, Stump experimentally — your reading position syncs through the same source automatically. Nothing extra to configure.</p>
        </div>
        <div class="docs-table-wrap">
          <table class="docs-table">
            <thead>
              <tr><th>Server</th><th>Catalog URL</th><th>Auth</th></tr>
            </thead>
            <tbody>
              <tr><td>Calibre-Web / CWA</td><td><code>https://your-server:8083/opds</code></td><td>HTTP Basic</td></tr>
              <tr><td>Grimmory / BookLore</td><td><code>https://your-server:6062/api/v1/opds</code></td><td>dedicated OPDS account</td></tr>
              <tr><td>Komga</td><td><code>https://your-server:25600/opds/v2/catalog</code></td><td>HTTP Basic — login is your <em>email</em></td></tr>
              <tr><td>Kavita</td><td><code>https://your-server:5000/api/opds/your-api-key</code></td><td>key in the URL</td></tr>
              <tr><td>Stump</td><td><code>https://your-server:10801/opds/v2.0/catalog</code></td><td>HTTP Basic</td></tr>
              <tr><td>Calibre content server</td><td><code>https://your-server:8080/opds</code></td><td>HTTP Basic, if enabled</td></tr>
              <tr><td>COPS</td><td><code>https://your-server/feed</code></td><td>install-dependent</td></tr>
              <tr><td>Storyteller</td><td><code>https://your-server:8001/opds</code></td><td>HTTP Basic</td></tr>
              <tr><td>Ubooquity</td><td><code>https://your-server:2202/opds-books</code></td><td>install-dependent</td></tr>
            </tbody>
          </table>
        </div>
      </section>
```

- [ ] **Step 2: Verify**

```bash
hugo --minify --gc
grep -c 'id="kobo-sync"' public/docs/index.html
grep -c 'id="opds"' public/docs/index.html
grep -o 'your-server' public/docs/index.html | wc -l
```

Expected: `1`, `1`, and `≥20`.

- [ ] **Step 3: Commit**

```bash
git add layouts/_default/docs.html
git commit -m "content(docs): Kobo sync and OPDS setup sections"
```

---

### Task 8: Troubleshooting + pre-footer help band

**Files:**
- Modify: `layouts/_default/docs.html` (replace both remaining markers)

- [ ] **Step 1: Replace `<!-- TASK 8: troubleshooting section -->`**

```html
      <!-- ── Troubleshooting ───────────────────────────────── -->
      <section class="docs-section" id="troubleshooting">
        <p class="eyebrow">When it doesn't<span class="dot">.</span></p>
        <h2>Troubleshooting</h2>
        <div class="faq-list">
          <details class="faq-item">
            <summary>Every push fails, or the server says “book not found”<span class="plus"></span></summary>
            <div class="faq-answer"><p>Almost always the KOReader sync URL: it must be the <strong>full</strong> base including the server's sub-path — <code>/kosync</code> on CWA, <code>/api/koreader</code> on Grimmory and BookLore. A bare host name can look connected and then fail on every sync.</p><p>If the URL is right, check the book: KOReader sync matches by file hash, so the copy in Kios must be byte-identical to the server's. Download it through the server's catalog rather than importing a different copy.</p></div>
          </details>
          <details class="faq-item">
            <summary>The server never matches any of my books<span class="plus"></span></summary>
            <div class="faq-answer"><p>Several servers only compute matching hashes during a scan. On Komga, enable <em>“Compute hash for KOReader”</em> and rescan. On Kavita, libraries created before v0.8.7 need a one-time forced scan. On Stump, enable KOReader-compatible hashes, then rescan.</p></div>
          </details>
          <details class="faq-item">
            <summary>Kios and my Kobo show different percentages<span class="plus"></span></summary>
            <div class="faq-answer"><p>Kobo firmware and Kios count whole-book progress differently, so after a handoff the two percentages can disagree while the chapter — and your actual position — are correct. A quirk of the device, not data loss.</p></div>
          </details>
          <details class="faq-item">
            <summary>Nothing syncs the first time I open a book<span class="plus"></span></summary>
            <div class="faq-answer"><p>Normal: the server has no position for that book yet. Kios pushes yours when you background the app or close the book, and your other device picks it up on its next sync.</p></div>
          </details>
        </div>
      </section>
```

- [ ] **Step 2: Replace `<!-- TASK 8: pre-footer band -->`**

```html
  <!-- ── Pre-footer ────────────────────────────────────────── -->
  <section class="docs-prefooter">
    <div class="wrap">
      <p class="lede">Running a server that isn't listed, or stuck on a step?</p>
      <a class="discord-btn" href="https://discord.gg/spTFCkhP" target="_blank" rel="noopener">
        <svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M20.317 4.3698a19.7913 19.7913 0 0 0-4.8851-1.5152.0741.0741 0 0 0-.0785.0371c-.211.3753-.4447.8648-.6083 1.2495-1.8447-.2762-3.68-.2762-5.4868 0-.1636-.3933-.4058-.8742-.6177-1.2495a.077.077 0 0 0-.0785-.037 19.7363 19.7363 0 0 0-4.8852 1.515.0699.0699 0 0 0-.0321.0277C.5334 9.0458-.319 13.5799.0992 18.0578a.0824.0824 0 0 0 .0312.0561c2.0528 1.5076 4.0413 2.4228 5.9929 3.0294a.0777.0777 0 0 0 .0842-.0276c.4616-.6304.8731-1.2952 1.226-1.9942a.076.076 0 0 0-.0416-.1057c-.6528-.2476-1.2743-.5495-1.8722-.8923a.077.077 0 0 1-.0076-.1277c.1258-.0943.2517-.1923.3718-.2914a.0743.0743 0 0 1 .0776-.0105c3.9278 1.7933 8.18 1.7933 12.0614 0a.0739.0739 0 0 1 .0785.0095c.1202.099.246.1981.3728.2924a.077.077 0 0 1-.0066.1276 12.2986 12.2986 0 0 1-1.873.8914.0766.0766 0 0 0-.0407.1067c.3604.698.7719 1.3628 1.225 1.9932a.076.076 0 0 0 .0842.0286c1.961-.6067 3.9495-1.5219 6.0023-3.0294a.077.077 0 0 0 .0313-.0552c.5004-5.177-.8382-9.6739-3.5485-13.6604a.061.061 0 0 0-.0312-.0286zM8.02 15.3312c-1.1825 0-2.1569-1.0857-2.1569-2.419 0-1.3332.9555-2.4189 2.157-2.4189 1.2108 0 2.1757 1.0952 2.1568 2.419 0 1.3332-.9555 2.4189-2.1569 2.4189zm7.9748 0c-1.1825 0-2.1569-1.0857-2.1569-2.419 0-1.3332.9554-2.4189 2.1569-2.4189 1.2108 0 2.1757 1.0952 2.1568 2.419 0 1.3332-.946 2.4189-2.1568 2.4189Z"/></svg>
        Ask on Discord
      </a>
    </div>
  </section>
```

- [ ] **Step 3: Verify all TOC anchors resolve and no markers remain**

```bash
hugo --minify --gc
grep -c 'TASK [0-9]' layouts/_default/docs.html
for id in how-it-works servers koreader-sync kobo-sync opds troubleshooting; do grep -c "id=\"$id\"" public/docs/index.html; done
```

Expected: `0` (all markers consumed), then six lines of `1`.

- [ ] **Step 4: Commit**

```bash
git add layouts/_default/docs.html
git commit -m "content(docs): troubleshooting + Discord pre-footer"
```

---

### Task 9: Docs links everywhere, CLAUDE.md, final verification

**Files:**
- Modify: `layouts/partials/nav.html`
- Modify: `layouts/partials/footer.html`
- Modify: `CLAUDE.md`

- [ ] **Step 1: Add Docs to the nav partial**

In `layouts/partials/nav.html`, after the FAQ link, add:

```html
      <a href="/docs/" class="hide-sm">Docs</a>
```

- [ ] **Step 2: Add Docs to the footer partial**

In `layouts/partials/footer.html`, in the `App` column's `<ul>`, after the Statistics `<li>`, add:

```html
          <li><a href="/docs/">Docs</a></li>
```

- [ ] **Step 3: Update CLAUDE.md**

In the Architecture section, replace the `layouts/_default/single.html` bullet with:

```markdown
- `layouts/_default/privacy.html` / `docs.html` — hardcoded per-page layouts, selected via
  `layout:` frontmatter in the corresponding `content/*.md` stub (which exists only to
  create the route). There is deliberately no generic `single.html`.
- `layouts/partials/nav.html` + `footer.html` — shared chrome; `.IsHome` switches link
  prefixes (`#faq` vs `/#faq`).
```

And append to the Conventions section:

```markdown
- `/docs/` server matrix + setup values are hand-maintained; source of truth is the app
  repo: `~/Git/kios/docs/technical/sync-backends/README.md`. Update the page when the
  app's compatibility matrix changes.
```

- [ ] **Step 4: Full verification**

```bash
hugo --minify --gc
# Docs link present on all three pages (nav + footer = 2 each):
for p in index.html privacy/index.html docs/index.html; do grep -o 'href=/docs/' "public/$p" | wc -l; done
# No external font/css leaks, no broken partials:
grep -rn "googleapis\|gstatic" public/docs/index.html; echo "fonts-clean: $?"
# TOC ↔ section ids still consistent:
grep -o 'href="#[a-z-]*"' public/docs/index.html | sort -u
```

Expected: three lines of `2`; `fonts-clean: 1`; the six expected anchors (`#how-it-works`, `#kobo-sync`, `#koreader-sync`, `#opds`, `#servers`, `#troubleshooting`).

Note: minified output may collapse `href="/docs/"` to `href=/docs/` — the grep above accounts for that; if it returns 0, re-check with the quoted form.

- [ ] **Step 5: Visual spot-check (manual)**

```bash
hugo server
```

Open `http://localhost:1313/docs/` and check: light + dark (toggle macOS appearance), ~375 px width (matrix scrolls horizontally inside `.docs-table-wrap`, no page overflow), expandables open/close with the plus animation, nav Docs link highlighted states.

- [ ] **Step 6: Commit**

```bash
git add layouts/partials CLAUDE.md
git commit -m "feat(nav): Docs link in nav + footer; note matrix source of truth"
```

---

## Self-review (done at write time)

- **Spec coverage:** nav/footer link ✓ (T9), head+TOC ✓ (T4), how-sync-works ✓ (T4), matrix w/ 11 rows + badges + anchors ✓ (T5), three setup blocks w/ field rows + per-server details ✓ (T6/T7), troubleshooting ✓ (T8), Discord pre-footer ✓ (T8), privacy rename ✓ (T2), partials extraction ✓ (T1), CSS-tokens-only ✓ (T3), SEO meta ✓ (T4), CLAUDE.md source-of-truth ✓ (T9), `/privacy/` byte-identical ✓ (T1/T2 diffs).
- **Placeholders:** none — every step carries full code/commands.
- **Consistency:** class names used in HTML (`docs-toc`, `docs-table-wrap`, `badge-verified`, `field-row`, `docs-prefooter`, `docs-fine`) all defined in Task 3 CSS; section ids match TOC hrefs; partial names match `{{ partial }}` calls.
