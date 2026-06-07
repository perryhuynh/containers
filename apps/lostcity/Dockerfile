# syntax=docker/dockerfile:1

ARG VERSION

FROM mirror.gcr.io/oven/bun:1.2.23-alpine@sha256:0841c588f6304300baf1d395ae339ce09a6e18c4b6a7cdd4fddcbdb87a2f096a AS client-builder
ARG VERSION

WORKDIR /build/client
RUN wget -qO- "https://github.com/LostCityRS/Client-TS/archive/refs/heads/${VERSION}.tar.gz" \
    | tar xzf - --strip-components=1 \
    && HUSKY=0 bun install --frozen-lockfile \
    && bun run build

FROM mirror.gcr.io/oven/bun:1.2.23-alpine@sha256:0841c588f6304300baf1d395ae339ce09a6e18c4b6a7cdd4fddcbdb87a2f096a AS engine-builder
ARG VERSION

RUN apk add --no-cache \
        openjdk17-jre-headless

WORKDIR /build
RUN mkdir engine content \
    && wget -qO- "https://github.com/LostCityRS/Engine-TS/archive/refs/heads/${VERSION}.tar.gz" \
        | tar xzf - -C engine --strip-components=1 \
    && wget -qO- "https://github.com/LostCityRS/Content/archive/refs/heads/${VERSION}.tar.gz" \
        | tar xzf - -C content --strip-components=1
COPY --from=client-builder /build/client/out /build/client/out

WORKDIR /build/engine
RUN HUSKY=0 bun install --frozen-lockfile \
    && cp /build/client/out/client.js public/client/client.js \
    && cp /build/client/out/tinymidipcm.wasm public/client/tinymidipcm.wasm \
    && BUILD_SRC_DIR=/build/content bun run build \
    && bun run sqlite:migrate

FROM mirror.gcr.io/oven/bun:1.2.23-alpine@sha256:0841c588f6304300baf1d395ae339ce09a6e18c4b6a7cdd4fddcbdb87a2f096a

RUN apk add --no-cache \
        bash \
        ca-certificates \
        catatonit \
        openjdk17-jre-headless \
        tzdata

COPY --from=engine-builder /build/engine /app/engine
COPY --from=engine-builder /build/content /app/content

RUN chown -R root:root /app \
    && chmod -R 755 /app \
    && rm -f /app/engine/db.sqlite \
    && ln -s /config/db.sqlite /app/engine/db.sqlite \
    && mkdir -p /config /app/engine/data \
    && rm -rf /app/engine/data/players \
    && ln -s /config/players /app/engine/data/players \
    && chown -R nobody:nogroup /config /app/engine/data /app/content/pack

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
