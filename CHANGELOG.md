# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.1] - 2026-11-13

### Fixed

- The `HYPERFLEET-CNF-001` client action depends on the desire type. ReadDesire and DeleteDesire have no update, so "read, then update" applied only to ApplyDesire (HYPERFLEET-1923)
- The sweeper's owner exemption does not take effect until HYPERFLEET-1937 changes the shared store interface. Until then the sweeper gets `HYPERFLEET-CNF-004` on objects that a different caller owns (HYPERFLEET-1923)

## [0.2.0] - 2026-11-12

### Added

- The five REST v1 operations under `/partitions/{partition}/desires`: list, get, write, write status, and delete, with the status codes, the compare-and-swap rules, keyset pagination, the delete read-after-timeout rule, and the owner binding from the Desire Store detailed design (HYPERFLEET-1821)
- `DesireId` with the colon encoding, and the `Desire`, `DesireReference`, `DesireList`, `DesireWrite`, and `StatusWrite` schemas (HYPERFLEET-1821)
- RFC 9457 problem responses for 400, 401, 403, 404, 409, 422, 429, 500, 503, and a default response for unlisted statuses, with `HYPERFLEET-CNF-001` to `HYPERFLEET-CNF-004` as the four 409 codes (HYPERFLEET-1821)
- Bearer authentication scheme, and the v1 compatibility rules in the service description (HYPERFLEET-1821)
- `make check-types` and a CI step that build Go types and a client generated from the schema with `oapi-codegen` (HYPERFLEET-1821)

### Changed

- Go version of the root module from 1.25.0 to 1.26.0 (HYPERFLEET-1821)

## [0.1.0] - 2026-11-11

### Added

- Repository scaffold from `hyperfleet-api-spec-template`: TypeSpec build, Spectral lint, CI, release workflow, and pre-commit hooks
- Go module `github.com/openshift-hyperfleet/hyperfleet-desire-store-spec` with the `schemas` package that embeds the generated contract
- Service definition with the `/api/hyperfleet/desire-store/v1` route prefix and no operations yet

[Unreleased]: https://github.com/openshift-hyperfleet/hyperfleet-desire-store-spec/compare/v0.2.1...HEAD
[0.2.1]: https://github.com/openshift-hyperfleet/hyperfleet-desire-store-spec/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/openshift-hyperfleet/hyperfleet-desire-store-spec/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/openshift-hyperfleet/hyperfleet-desire-store-spec/releases/tag/v0.1.0
