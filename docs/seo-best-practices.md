# SEO best practices

A practical, current (2026) reference for search and social optimization,
plus a record of how each item is applied to the Kios site. It is scoped to a
small, mostly single-page marketing site served as static HTML by Hugo + Caddy.

---

## 1. On-page fundamentals

These are the highest-leverage, lowest-effort wins. Every indexable page should
have all of them.

- **Unique `<title>` per page** — 50–60 characters so it isn't truncated in the
  SERP. Put the primary keyword/brand near the front.
- **Unique `<meta name="description">`** — 140–160 characters. It is not a
  ranking factor, but it is the click-through pitch shown under the title.
- **Exactly one `<h1>` per page** that states what the page is about, followed
  by a sensible `<h2>`/`<h3>` outline. Search engines and screen readers both
  rely on this hierarchy.
- **Descriptive, keyword-aware copy** in real text (not baked into images).
- **Meaningful `alt` text** on content images; empty `alt=""` on purely
  decorative ones so assistive tech skips them.
- **Descriptive link text** ("Join the TestFlight beta", not "click here").
- **Clean, stable, lowercase URLs** with trailing-slash consistency.

## 2. Crawlability & indexing

Help crawlers find everything once and avoid wasting crawl budget on
duplicates.

- **`robots.txt`** at the site root: allow crawling and point to the sitemap.
- **`sitemap.xml`** listing every canonical URL; submit it in Google Search
  Console and Bing Webmaster Tools.
- **Canonical URL** (`<link rel="canonical">`) on every page so query strings,
  trailing-slash variants, and http/https don't fragment ranking signals.
- **`<meta name="robots" content="index, follow">`** — the default, but being
  explicit avoids accidental `noindex`. Add `max-image-preview:large` so rich
  image previews are allowed.
- **One canonical host.** Redirect `www` ⇄ apex and force HTTPS (301).
- Keep important pages reachable within a few clicks via internal links.

## 3. Social sharing (Open Graph & Twitter/X Cards)

When a link is pasted into Slack, Discord, iMessage, X, LinkedIn, or Facebook,
these tags control the preview card. Missing tags = an ugly, low-trust unfurl.

- **Open Graph**: `og:title`, `og:description`, `og:type`, `og:url`,
  `og:site_name`, `og:image`, `og:image:alt`, `og:locale`.
- **Twitter/X**: `twitter:card` (`summary_large_image` for a wide banner,
  `summary` for a small square thumbnail), `twitter:title`,
  `twitter:description`, `twitter:image`.
- **Image rules**:
  - `summary_large_image` wants **1200×630 px** (1.91:1). Keep text/logos
    inside the centre ~80% "safe zone".
  - `summary` uses a square thumbnail (a square app icon works well here).
  - The image URL **must be absolute** (`https://…`) — crawlers reject relative
    paths.
  - Use PNG or JPG (broadest support), ideally < 1 MB. WebP is fine for the
    page itself but is unreliable for OG crawlers, so keep a PNG/JPG for the
    card.
- **Validate** with the [Facebook Sharing Debugger](https://developers.facebook.com/tools/debug/),
  the X Card validator, and LinkedIn's Post Inspector. These also bust the
  platforms' caches after you change an image.

## 4. Structured data (JSON-LD / schema.org)

Structured data is the cheapest, highest-leverage technical investment in 2026.
It is not a direct ranking factor, but it amplifies entity understanding for
classic rich results, AI/answer engines, and voice search. Use **JSON-LD** in a
`<script type="application/ld+json">` and validate with Google's
[Rich Results Test](https://search.google.com/test/rich-results) and the
[Schema Markup Validator](https://validator.schema.org/).

High-value types for this site:

- **Organization / WebSite** — establishes the brand entity, logo, and official
  links (`sameAs`).
- **SoftwareApplication / MobileApplication** — the right type for an app
  landing page: name, `operatingSystem`, `applicationCategory`, `offers`
  (price/currency — `0` for the free beta), and `screenshot`s.
- **FAQPage** — marks up the on-page Q&A. (Note Google narrowed FAQ rich
  results to authoritative gov/health sites in 2023, but the markup still helps
  AI answer engines and general entity understanding, so it remains worth
  emitting.)

Keep the markup in sync with what's visible on the page — never mark up content
the user can't see.

## 5. Performance & Core Web Vitals

Speed is a ranking signal and a conversion lever. Targets (75th percentile,
mobile):

- **LCP** (Largest Contentful Paint) < **2.5 s** — preload/`eager`-load the hero
  image, lazy-load the rest.
- **INP** (Interaction to Next Paint) < **200 ms** — minimal, passive JS.
- **CLS** (Cumulative Layout Shift) < **0.1** — always set `width`/`height`
  (or `aspect-ratio`) on images and media so nothing reflows.

Supporting tactics: compress images (WebP/AVIF), `loading="lazy"` +
`decoding="async"` below the fold, minify CSS/JS, serve gzip/zstd, set
`Cache-Control`, and avoid render-blocking third-party scripts (load analytics
`async`).

## 6. Mobile & accessibility

- **Mobile-first indexing**: Google ranks the mobile rendering, so it must
  contain the same content, links, and structured data as desktop.
- `<meta name="viewport" content="width=device-width, initial-scale=1">`.
- `<html lang="…">` set correctly for language detection.
- `theme-color` (with light/dark variants) for the browser/OS chrome.
- `apple-touch-icon` for iOS home-screen bookmarks.
- Sufficient colour contrast and visible focus states — accessibility and SEO
  overlap heavily.

## 7. Ongoing / off-page

- Verify the site in **Google Search Console** + **Bing Webmaster Tools**;
  watch Coverage, Core Web Vitals, and the performance report.
- Earn relevant inbound links and consistent brand mentions.
- Keep content fresh and accurate; fix broken links and crawl errors.

---

## How this is applied to the Kios site

| Area | Where | Notes |
|------|-------|-------|
| Title & description | `layouts/partials/seo.html` | Owned by the partial; each layout passes unique `title`/`description` args. |
| Single `<h1>`, heading outline | page layouts | Hero `<h1>`, `<h2>`/`<h3>` sections. |
| Canonical, robots meta, OG, Twitter, theme-color, icons | `layouts/partials/seo.html` | Shared partial included from the home, privacy and docs layouts. |
| Structured data (Organization, WebSite, SoftwareApplication, FAQPage) | `layouts/partials/seo.html` | JSON-LD, built from real page data. |
| FAQ single source of truth | `data/faq.yaml` | Drives both the visible `<details>` list and the FAQPage schema, so they can't drift. |
| `robots.txt` + sitemap | `layouts/robots.txt` (+ Hugo's auto `sitemap.xml`), `enableRobotsTXT` in `hugo.toml` | robots points at the sitemap; taxonomy kinds disabled so no phantom URLs. |
| Social/OG params | `hugo.toml` `[params]` | `ogImage`, `ogImageAlt`, social links. |
| Performance | existing layout/CSS | Hero image `loading="eager"`, others `lazy`; `width`/`height` set; WebP screenshots; minified CSS; `async` analytics; gzip/zstd + cache headers in `Caddyfile`. |

### Follow-ups worth doing

- **Add a dedicated 1200×630 PNG/JPG OG image** (e.g. `static/site-assets/og-image.png`)
  and switch `twitter:card` to `summary_large_image`. The site currently falls
  back to the square 1024×1024 app icon with a `summary` card, which is valid
  but less eye-catching than a wide banner. Update `params.ogImage` and
  `params.ogImageAlt` in `hugo.toml` once the image exists.
- After deploy, **submit `sitemap.xml`** in Google Search Console and Bing
  Webmaster Tools.
- Run the **Rich Results Test** and the **Facebook/X/LinkedIn** preview
  debuggers against the live URL to confirm the cards and schema render.
