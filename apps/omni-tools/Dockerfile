# syntax=docker/dockerfile:1

ARG VERSION

FROM mirror.gcr.io/library/node:24.18.0-slim@sha256:b31e7a42fdf8b8aa5f5ed477c72d694301273f1069c5a2f71d53c6482e99a2fc AS builder
ARG VERSION
ENV \
    HUSKY=0 \
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        ca-certificates \
        wget \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
RUN wget -qO- "https://github.com/iib0011/omni-tools/archive/refs/tags/v${VERSION}.tar.gz" \
    | tar xzf - --strip-components=1 \
    && npm ci --ignore-scripts \
    && npm run build

FROM mirror.gcr.io/library/caddy:2.11.4-alpine@sha256:5f5c8640aae01df9654968d946d8f1a56c497f1dd5c5cda4cf95ab7c14d58648

RUN apk add --no-cache catatonit \
    && apk add --no-cache --virtual .cap libcap \
    # Remove cap_net_bind_service file capability so the binary can be exec'd
    # under no_new_privs (allowPrivilegeEscalation: false); it binds :8080 only.
    && setcap -r /usr/bin/caddy \
    && apk del .cap

COPY --from=builder /build/dist /usr/share/caddy

COPY <<'CADDY' /etc/caddy/Caddyfile
{
	admin off
	persist_config off
	auto_https off
}

:8080 {
	root * /usr/share/caddy
	encode gzip zstd
	try_files {path} /index.html
	file_server
	log {
		output stdout
		format console
	}
}
CADDY

RUN caddy validate --adapter caddyfile --config /etc/caddy/Caddyfile

COPY . /
RUN chmod 755 /entrypoint.sh

ENV \
    XDG_CONFIG_HOME=/tmp \
    XDG_DATA_HOME=/tmp

USER nobody:nogroup
EXPOSE 8080/tcp

ENTRYPOINT ["/usr/bin/catatonit", "--", "/entrypoint.sh"]
