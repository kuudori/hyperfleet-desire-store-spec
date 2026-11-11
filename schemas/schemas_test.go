package schemas

import (
	"bytes"
	"testing"
)

func TestFSContainsOpenAPISchema(t *testing.T) {
	data, err := FS.ReadFile("desire-store/openapi.yaml")
	if err != nil {
		t.Fatalf("read embedded schema: %v", err)
	}
	if !bytes.HasPrefix(data, []byte("openapi: 3.")) {
		t.Fatalf("embedded schema does not start with an OpenAPI 3 version line")
	}
}
