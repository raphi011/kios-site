# --- build stage: render the Hugo site ---
FROM hugomods/hugo:exts AS build
WORKDIR /src
COPY . .
RUN hugo --minify --gc --destination /public

# --- runtime stage: caddy serving the static output ---
FROM caddy:2-alpine
COPY Caddyfile /etc/caddy/Caddyfile
COPY --from=build /public /srv
EXPOSE 8080
