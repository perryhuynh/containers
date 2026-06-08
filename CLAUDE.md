# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A collection of OCI container images for self-hosted applications. Each app is a self-contained directory under `apps/<app>/` that builds a rootless, multi-arch image published to `ghcr.io/<owner>/<app>`. There is no application source here — images wrap upstream projects.

Conventions all images follow (enforced by review, not tooling): rootless (default `nobody:nogroup` / `65534`), one process per container, log to stdout, no s6-overlay/gosu, persistent config hardcoded to `/config`, base on Alpine or Ubuntu/Debian.

## Per-app layout

An app lives entirely in `apps/<app>/`:

- `Dockerfile` — multi-stage build. Receives `ARG VERSION` (upstream version) and `ARG VENDOR` (repo owner, CI-injected).
- `docker-bake.hcl` — declares `APP`, `VERSION`, `SOURCE` variables and the `image` / `image-local` / `image-all` targets. The `VERSION` default carries a `# renovate:` annotation that drives automated upstream bumps.
- `entrypoint.sh` — run via `catatonit` as PID 1.
- `container_test.go` — `package main`, uses `testhelpers` to assert the built image works.

Shared files in `include/` (e.g. `.dockerignore`) are rsynced into the app dir as the build context — locally by the `local-build` task, in CI by the build job. They are not committed into each app.

## Common commands

Tooling is pinned via [mise](https://mise.jdx.dev) (`.mise/config.toml`). Run `mise install` first.

```sh
# Build an app image locally and run its Go tests against it
mise run local-build <app>

# Trigger a remote build via GitHub Actions (release defaults to false)
mise run remote-build <app> [release]

# Run one app's tests against an already-built image
TEST_IMAGE=<image-ref> go test -v ./apps/<app>/...

# Run a single test by name
TEST_IMAGE=<image-ref> go test -v ./apps/<app>/... -run TestName
```

`local-build` runs in `.cache/`: it rsyncs `include/` + the app dir there, `docker buildx bake`s a local image, then runs the app's tests with `TEST_IMAGE` set to the freshly built image. Tests need a working Docker daemon — `testhelpers` drives [testcontainers-go](https://golang.testcontainers.org/).

## Test framework

`testhelpers/testhelpers.go` is the shared assertion library for all `container_test.go` files. Key helpers:

- `GetTestImage(default)` — reads `TEST_IMAGE` env var, falling back to a default ref. Always seed test image refs through this so the same test serves both local and CI builds.
- `TestFileExists` / `TestCommandSucceeds` — run the image with an overridden entrypoint, wait for exit, assert exit code 0.
- `TestHTTPEndpoint` — start the container, wait for a port + HTTP status, with optional startup timeout.

Container stdout/stderr is piped into `t.Log`, so a failing test surfaces the container's own output.

## CI / release pipeline

- `release.yaml` triggers on push to `main` touching `apps/**` (or manual dispatch). It diffs changed app directories and fans out one `app-builder.yaml` run per changed app.
- `app-builder.yaml` is the core reusable workflow: plan (compute tags/platforms from `docker-bake.hcl` via the `app-options`/`app-versions` composite actions) → build per-platform digests → merge into a manifest list → attest (SBOM + build provenance) → test (PR/non-release only) → announce/notify.
- Composite actions in `.github/actions/` (`app-options`, `app-versions`, `app-tests`, etc.) read metadata straight out of `docker-bake.hcl` with `docker buildx bake --list`. Keep bake variable names (`APP`, `VERSION`, `SOURCE`) stable — these actions depend on them.
- Images are tagged `rolling` (release) or `sandbox` (PR builds), plus semver tags when the upstream version parses as semver and it's a release. Images are unsigned-tag + sha256-digest pinned; releases push build cache to `ghcr.io/<owner>/build_cache`.

## Adding or updating an app

- A new app is a new `apps/<app>/` directory with the four files above; CI picks it up automatically from the changed-paths diff.
- Version bumps are normally automated: Renovate (`.renovaterc.json5`) parses the `# renovate:` annotation above the `VERSION` default in `docker-bake.hcl` (and similar annotations in `Dockerfile`) and opens a `release(<app>):` PR. Bake-file bumps auto-merge once tests pass.
- Commit scope is the app name (e.g. `fix(lostcity): ...`, `release(lostcity): ...`).

## Formatting

`oxfmt` formats shell/config; `prettier`-style ignores in `.prettierignore`; `.editorconfig` governs indentation. Git hooks run via `lefthook` (remote config from `home-operations/.github`), installed by the mise `postinstall` hook.
