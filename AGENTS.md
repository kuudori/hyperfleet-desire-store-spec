# HyperFleet Desire Store API Spec - AI Agent Context

This repository holds the OpenAPI contract for the HyperFleet Desire Store REST v1 API. The contract is written in TypeSpec, compiled to OpenAPI 3.0, committed under `schemas/desire-store/`, and embedded in the Go package `schemas`.

## Source of truth

The [Desire Store detailed design](https://github.com/openshift-hyperfleet/architecture/blob/main/hyperfleet/docs/desire-store-dd.md) decides the routes, the desire identifier encoding, the wire schemas, the status codes, the RFC 9457 error responses, compare-and-swap, and pagination. Transcribe it. When the design has a gap or a conflict, raise it against the design. Do not decide it here.

## Commands

```bash
npm install          # install the TypeSpec compiler and Spectral
make generate        # compile main.tsp into schemas/desire-store/openapi.yaml
make lint            # Spectral lint at --fail-severity warn, then go vet
make test            # Go tests
make verify-schema   # fail when the committed schema differs from the sources
```

## Rules

**DO NOT:**

- Edit `schemas/desire-store/openapi.yaml` by hand. Change the `.tsp` sources and regenerate.
- Commit `node_modules/` or `tsp-output-*` directories.
- Import the `hyperfleet` package from `hyperfleet-api-spec`. The Desire Store contract is independent of the cluster API.

**DO:**

- Commit the regenerated schema with every TypeSpec change.
- Bump the version in `main.tsp` and add a `CHANGELOG.md` entry for every contract change. CI rejects a `.tsp` change without a version bump.
- Use snake_case for new v1 wire fields. Inherited desire fields keep their established spellings (`kubeContent`, `resource_id`).

## Version bump and changelog

1. Keep `## [Unreleased]` at the top, then add `## [X.Y.Z] - YYYY-MM-DD`.
2. List changes under `Added`, `Changed`, `Fixed`, or `Removed`.
3. Update the comparison links at the bottom.
4. Follow [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## Releases

The release workflow tags `vX.Y.Z` from the `@info` version in `main.tsp` on every push to `main` when the tag does not exist yet. The tag is the Go module version.
