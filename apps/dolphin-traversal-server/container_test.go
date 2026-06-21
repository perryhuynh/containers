package main

import (
	"testing"

	"github.com/home-operations/containers/testhelpers"
)

func Test(t *testing.T) {
	image := testhelpers.GetTestImage("ghcr.io/perryhuynh/dolphin-traversal-server:rolling")

	testhelpers.TestFileExists(t, image, "/usr/local/bin/traversal_server", nil)

	// The server binds UDP 6262 on startup; assert it actually listens.
	testhelpers.TestUDPListening(t, image, 6262, nil)
}
