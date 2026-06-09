<div align="center">

## Containers

_An opinionated collection of container images_

</div>

Welcome to our container images! If you are looking for a container, start by [browsing the GitHub Packages page for this repository's packages](https://github.com/orgs/perryhuynh/packages?repo_name=containers).

## Mission Statement

Our goal is to provide [semantically versioned](https://semver.org/), [rootless](https://rootlesscontaine.rs/), and [multi-architecture](https://www.docker.com/blog/multi-arch-build-and-images-the-simple-way/) containers for various applications.

We adhere to the [KISS principle](https://en.wikipedia.org/wiki/KISS_principle), logging to stdout, maintaining [one process per container](https://testdriven.io/tips/59de3279-4a2d-4556-9cd0-b444249ed31e/), avoiding tools like [s6-overlay](https://github.com/just-containers/s6-overlay), and building all images on top of [Alpine](https://hub.docker.com/_/alpine) or [Ubuntu](https://hub.docker.com/_/ubuntu).

## Features

### Tag Immutability

Containers built here do not use immutable tags in the traditional sense, as seen with [linuxserver.io](https://fleet.linuxserver.io/) or [Bitnami](https://bitnami.com/stacks/containers). Instead, we insist on pinning to the `sha256` digest of the image. While this approach is less visually appealing, it ensures functionality and immutability.

| Container                                            | Immutable |
| ---------------------------------------------------- | --------- |
| `ghcr.io/perryhuynh/lostcity:rolling`                | ❌        |
| `ghcr.io/perryhuynh/lostcity:274`                    | ❌        |
| `ghcr.io/perryhuynh/lostcity:rolling@sha256:8053...` | ✅        |
| `ghcr.io/perryhuynh/lostcity:274@sha256:8053...`     | ✅        |

_If pinning an image to the `sha256` digest, tools like [Renovate](https://github.com/renovatebot/renovate) can update containers based on digest or version changes._

### Rootless

By default the majority of our containers run as a non-root user (`65534:65534`), you are able to change the user/group by updating your configuration files.

#### Docker Compose

```yaml
services:
    lostcity:
        image: ghcr.io/perryhuynh/lostcity:274
        container_name: lostcity
        user: 1000:1000 # The data volume permissions must match this user:group
        read_only: true # May require mounting in additional dirs as tmpfs
        tmpfs:
            - /tmp:rw
        # ...
```

#### Kubernetes

Using a Flux [HelmRelease](https://fluxcd.io/flux/components/helm/helmreleases/) with the [bjw-s/app-template](https://github.com/bjw-s-labs/helm-charts/tree/main/charts/other/app-template) chart:

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
    name: lostcity
spec:
    # ...
    chartRef:
        kind: OCIRepository
        name: lostcity
    values:
        controllers:
            lostcity:
                containers:
                    app:
                        image:
                            repository: ghcr.io/perryhuynh/lostcity
                            tag: 274 # Pin to @sha256:... for immutability
                        securityContext: # May require mounting in additional dirs as emptyDir
                            allowPrivilegeEscalation: false
                            capabilities:
                                drop:
                                    - ALL
                            readOnlyRootFilesystem: true
        defaultPodOptions:
            securityContext:
                runAsNonRoot: true
                runAsUser: 1000
                runAsGroup: 1000
                fsGroup: 1000 # (Requires CSI support)
                fsGroupChangePolicy: OnRootMismatch # (Requires CSI support)
        persistence:
            config:
                existingClaim: lostcity # Mounted at /config
            tmp:
                type: emptyDir
                globalMounts:
                    - path: /tmp
```

### Passing Arguments to Applications

Some applications only allow certain configurations via command-line arguments rather than environment variables. For such cases, refer to the Kubernetes documentation on [defining commands and arguments for a container](https://kubernetes.io/docs/tasks/inject-data-application/define-command-argument-container/). Then, specify the desired arguments as shown below:

```yaml
args:
    - --port
    - "8080"
```

### Configuration Volume

For applications requiring persistent configuration data, the configuration volume is hardcoded to `/config` within the container. In most cases, this path cannot be changed.

### Verify Image Signature

These container images are signed using the [attest-build-provenance](https://github.com/actions/attest-build-provenance) action.

To verify that the image was built by GitHub CI, use the following command:

```sh
gh attestation verify --repo perryhuynh/containers oci://ghcr.io/perryhuynh/${APP}:${TAG}
```

or by using [cosign](https://github.com/sigstore/cosign):

```sh
cosign verify-attestation --new-bundle-format --type slsaprovenance1 \
    --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
    --certificate-identity-regexp "^https://github.com/perryhuynh/containers/.github/workflows/app-builder.yaml@refs/heads/main" \
    ghcr.io/perryhuynh/${APP}:${TAG}
```

### Eschewed Features

This repository does not support multiple "channels" for the same application — each application is published from a single upstream branch or variant. This approach ensures consistency and focuses on streamlined builds.

## Contributing

We encourage the use of official upstream container images whenever possible. However, contributing to this repository might make sense if:

- The upstream application is **actively maintained**.
- **And** one of the following applies:
    - no official image exists.
    - the official image does not support **multi-architecture builds**.
    - the official image uses tools like **s6-overlay**, **gosu**, or other unconventional initialization mechanisms.
    - does not tag releases.

## Deprecations

Containers in this repository may be deprecated for the following reasons:

1. The upstream application is **no longer actively maintained**.
2. An **official upstream container exists** that aligns with this repository's mission statement.
3. The **maintenance burden** is unsustainable, such as frequent build failures or instability.

**Note**: Deprecated containers will be announced with a release and remain available in the registry for 6 months before removal.

## Credits

This repository draws inspiration and ideas from the home-ops community, [hotio.dev](https://hotio.dev/), and [linuxserver.io](https://www.linuxserver.io/) contributors.
