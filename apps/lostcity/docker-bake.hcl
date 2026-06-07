target "docker-metadata-action" {}

variable "APP" {
  default = "lostcity"
}

variable "VERSION" {
  // renovate: datasource=git-refs depName=https://github.com/LostCityRS/Engine-TS versioning=loose
  default = "530-wip"
}

variable "SOURCE" {
  default = "https://github.com/LostCityRS/Engine-TS"
}

group "default" {
  targets = ["image-local"]
}

target "image" {
  inherits = ["docker-metadata-action"]
  args = {
    VERSION = "${VERSION}"
  }
  labels = {
    "org.opencontainers.image.source" = "${SOURCE}"
  }
}

target "image-local" {
  inherits = ["image"]
  output = ["type=docker"]
  tags = ["${APP}:${VERSION}"]
}

target "image-all" {
  inherits = ["image"]
  platforms = [
    "linux/amd64",
    "linux/arm64"
  ]
}
