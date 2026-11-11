# hyperfleet-desire-store-spec

The OpenAPI contract for the HyperFleet Desire Store REST v1 API, published as a versioned Go module.

The Desire Store API service, the Applier client, and the Adapter client build against this contract. The contract comes from the [Desire Store detailed design](https://github.com/openshift-hyperfleet/architecture/blob/main/hyperfleet/docs/desire-store-dd.md). Per [ADR-0003](https://github.com/openshift-hyperfleet/architecture/blob/main/hyperfleet/adrs/0003-openapi-first-contract.md), the contract is reviewed before the implementation starts.

The repository started from [hyperfleet-api-spec-template](https://github.com/openshift-hyperfleet/hyperfleet-api-spec-template). It does not import the shared `hyperfleet` package from [hyperfleet-api-spec](https://github.com/openshift-hyperfleet/hyperfleet-api-spec), because the Desire Store does not use the cluster and nodepool models.

## Repository structure

```text
hyperfleet-desire-store-spec/
├── main.tsp                      # TypeSpec entry point: service, version, route prefix
├── tspconfig.yaml                # TypeSpec compiler configuration
├── build-schema.sh               # Compiles main.tsp into schemas/desire-store/openapi.yaml
├── schemas/
│   ├── desire-store/openapi.yaml # Generated OpenAPI 3.0 contract (committed)
│   └── schemas.go                # Go package that embeds the generated contract
└── Makefile                      # help, generate, build, lint, test, verify-schema, clean
```

## Using the contract from Go

```go
import dsschemas "github.com/openshift-hyperfleet/hyperfleet-desire-store-spec/schemas"

data, err := dsschemas.FS.ReadFile("desire-store/openapi.yaml")
```

Consumers generate their own types and clients from this file with `oapi-codegen`, as the HyperFleet API does with `hyperfleet-api-spec`.

## Development

```bash
npm install         # TypeSpec compiler and Spectral
make generate       # Compile main.tsp into schemas/desire-store/openapi.yaml
make lint           # Spectral lint at --fail-severity warn, then go vet
make test           # Go tests
make verify-schema  # Fail when the committed schema is out of date
make install-hooks  # pre-commit and commit-msg hooks
```

Commit the regenerated `schemas/desire-store/openapi.yaml` with every TypeSpec change. CI fails when it differs from the sources.

## Releases

On every push to `main`, the release workflow reads the version from the `@info` decorator in `main.tsp`. When no tag exists for that version, it creates the `vX.Y.Z` tag and a GitHub release with the generated contract attached. The tag is also the Go module version.

To release, bump the version in `main.tsp`, add a `CHANGELOG.md` entry, and merge. CI rejects a pull request that changes a `.tsp` file without a version bump.

## Compatibility

The `v1` route prefix is the compatibility boundary for Appliers. Within v1, operation behavior, authorization, compare-and-swap, and idempotency stay stable, and only optional additive fields are compatible changes. Releases before `1.0.0` carry no compatibility promise.
