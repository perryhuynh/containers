# syntax=docker/dockerfile:1

ARG VERSION

FROM mirror.gcr.io/library/debian:bookworm-slim@sha256:96e378d7e6531ac9a15ad505478fcc2e69f371b10f5cdf87857c4b8188404716 AS builder
ARG VERSION

# Dolphin's Externals are git submodules, so a source tarball will not work -- clone with
# submodules. USE_SYSTEM_LIBS=OFF forces the bundled Externals (fmt, mbedtls, curl, enet,
# ...) so the only host build deps are a compiler, cmake/ninja and git.
RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        ca-certificates \
        cmake \
        g++ \
        git \
        libbluetooth-dev \
        libevdev-dev \
        libudev-dev \
        libusb-1.0-0-dev \
        ninja-build \
        pkg-config \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN git init -q \
    && git remote add origin https://github.com/dolphin-emu/dolphin \
    && git fetch -q --depth 1 origin "${VERSION}" \
    && git checkout -q FETCH_HEAD \
    && git submodule update --init --recursive --depth 1

WORKDIR /src/build
# Disable every frontend/subsystem we do not need; we only build the traversal_server target.
RUN cmake -G Ninja .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DUSE_SYSTEM_LIBS=OFF \
        -DENABLE_QT=OFF \
        -DENABLE_NOGUI=OFF \
        -DENABLE_CLI_TOOL=OFF \
        -DENABLE_TESTS=OFF \
        -DENABLE_ANALYTICS=OFF \
        -DENABLE_AUTOUPDATE=OFF \
        -DENABLE_VULKAN=OFF \
        -DENABLE_SDL=OFF \
        -DENABLE_LTO=OFF \
        -DUSE_DISCORD_PRESENCE=OFF \
    && cmake --build . --target traversal_server \
    && cp "$(find . -type f -name traversal_server | head -1)" /traversal_server

FROM mirror.gcr.io/library/debian:bookworm-slim@sha256:96e378d7e6531ac9a15ad505478fcc2e69f371b10f5cdf87857c4b8188404716
ARG VERSION

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        catatonit \
        ca-certificates \
        tzdata \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /traversal_server /usr/local/bin/traversal_server
COPY . /
RUN chmod 755 /entrypoint.sh /usr/local/bin/traversal_server

USER nobody:nogroup
EXPOSE 6262/udp 6226/udp

ENTRYPOINT ["/usr/bin/catatonit", "--", "/entrypoint.sh"]
