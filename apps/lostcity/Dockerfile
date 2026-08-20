# syntax=docker/dockerfile:1

ARG VERSION

FROM mirror.gcr.io/oven/bun:1.4.0-alpine@sha256:07235578f79ef8c6f97d94aee7938e76f5cdba5f21ae5dbfdd3d3d38058437eb AS client-builder
ARG VERSION

WORKDIR /build/client
RUN wget -qO- "https://github.com/LostCityRS/Client-TS/archive/refs/heads/${VERSION}.tar.gz" \
    | tar xzf - --strip-components=1 \
    && HUSKY=0 bun install --frozen-lockfile \
    && bun run build

FROM mirror.gcr.io/library/node:24.19.0-slim@sha256:3638d9a6fe4030bd716be989438248074489337ba3275657f93595428be4fc03 AS engine-builder
ARG VERSION

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        ca-certificates \
        openjdk-17-jre-headless \
        wget \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
RUN mkdir engine content \
    && wget -qO- "https://github.com/LostCityRS/Engine-TS/archive/refs/heads/${VERSION}.tar.gz" \
        | tar xzf - -C engine --strip-components=1 \
    && wget -qO- "https://github.com/LostCityRS/Content/archive/refs/heads/${VERSION}.tar.gz" \
        | tar xzf - -C content --strip-components=1
COPY --from=client-builder /build/client/out /build/client/out

WORKDIR /build/engine
RUN HUSKY=0 npm ci \
    && cp /build/client/out/client.js public/client/client.js \
    && cp /build/client/out/tinymidipcm.wasm public/client/tinymidipcm.wasm \
    && BUILD_SRC_DIR=/build/content npm run build

FROM mirror.gcr.io/library/node:24.19.0-slim@sha256:3638d9a6fe4030bd716be989438248074489337ba3275657f93595428be4fc03

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        bash \
        ca-certificates \
        catatonit \
        openjdk-17-jre-headless \
        tzdata \
    && rm -rf /var/lib/apt/lists/*

COPY --from=engine-builder /build/engine /app/engine
COPY --from=engine-builder /build/content /app/content

RUN chown -R root:root /app \
    && chmod -R 755 /app \
    && rm -f /app/engine/db.sqlite \
    && ln -s /config/db.sqlite /app/engine/db.sqlite \
    && mkdir -p /config /app/engine/data \
    && rm -rf /app/engine/data/players \
    && ln -s /config/players /app/engine/data/players \
    && mkdir -p /usr/share/lostcity \
    && cp -a /app/content/pack /usr/share/lostcity/bootstrap-pack \
    && LOSTCITY_PACK_HASH="$(find /usr/share/lostcity/bootstrap-pack -type f | sort | xargs sha256sum | sha256sum | awk '{print $1}')" \
    && printf '%s\n' "${LOSTCITY_PACK_HASH}" > /usr/share/lostcity/bootstrap-pack/.lostcity-pack-hash \
    && chown -R nobody:nogroup /config /app/engine/data /app/content/pack /usr/share/lostcity

COPY . /
RUN chmod 755 /entrypoint.sh

ENV \
    BUILD_SRC_DIR=/app/content \
    DB_BACKEND=sqlite \
    EASY_STARTUP=true \
    NODE_PORT=43594 \
    WEB_MANAGEMENT_PORT=8898 \
    WEB_PORT=8888

USER nobody:nogroup
WORKDIR /app/engine
VOLUME ["/config"]
EXPOSE 8888/tcp 8898/tcp 43594/tcp

ENTRYPOINT ["/usr/bin/catatonit", "--", "/entrypoint.sh"]
