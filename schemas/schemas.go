// Package schemas exposes the generated HyperFleet Desire Store OpenAPI schema as an embedded filesystem.
// Consumers import this package to read the versioned contract without vendoring a local copy.
//
// Usage:
//
//	import dsschemas "github.com/openshift-hyperfleet/hyperfleet-desire-store-spec/schemas"
//
//	data, err := dsschemas.FS.ReadFile("desire-store/openapi.yaml")
package schemas

import "embed"

//go:embed desire-store/openapi.yaml
var FS embed.FS
