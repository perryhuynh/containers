package main

import (
	"testing"
	"time"

	"github.com/home-operations/containers/testhelpers"
)

func Test(t *testing.T) {
	image := testhelpers.GetTestImage("ghcr.io/perryhuynh/omni-tools:rolling")

	testhelpers.TestFileExists(t, image, "/usr/share/caddy/index.html", nil)

	testhelpers.TestHTTPEndpoint(t, image, testhelpers.HTTPTestConfig{
		Port:       "8080",
		Path:       "/",
		StatusCode: 200,
		Timeout:    1 * time.Minute,
	}, nil)
}
