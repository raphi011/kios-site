# --- build stage: render the Hugo site ---
# Pinned: the floating `exts` tag froze at hugo 0.154.5 (scheme change);
# keep this in step with the local dev hugo version.
FROM hugomods/hugo:0.162.1 AS build
WORKDIR /src
COPY . .
RUN hugo --minify --gc --destination /public

# --- runtime stage: caddy serving the static output ---
FROM caddy:2-alpine
COPY Caddyfile /etc/caddy/Caddyfile
COPY --from=build /public /srv
EXPOSE 8080
