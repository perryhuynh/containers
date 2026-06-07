package main

import (
	"testing"
	"time"

	"github.com/home-operations/containers/testhelpers"
)

func Test(t *testing.T) {
	image := testhelpers.GetTestImage("ghcr.io/home-operations/lostcity:rolling")

	testhelpers.TestFileExists(t, image, "/app/engine/src/app.ts", nil)
	testhelpers.TestFileExists(t, image, "/app/content/pack/loc.pack", nil)
	testhelpers.TestFileExists(t, image, "/app/engine/public/client/client.js", nil)

	testhelpers.TestHTTPEndpoint(t, image, testhelpers.HTTPTestConfig{
		Port:       "8888",
		Path:       "/rs2.cgi",
		StatusCode: 200,
		Timeout:    3 * time.Minute,
	}, nil)
}
