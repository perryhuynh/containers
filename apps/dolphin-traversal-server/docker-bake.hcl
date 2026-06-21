target "docker-metadata-action" {}

variable "APP" {
  default = "dolphin-traversal-server"
}

variable "VERSION" {
  // renovate: datasource=git-refs depName=https://github.com/dolphin-emu/dolphin branch=master versioning=loose
  default = "a426df48234f0e59cb64684a35a389cda56087ce"
}

variable "SOURCE" {
  default = "https://github.com/dolphin-emu/dolphin"
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
