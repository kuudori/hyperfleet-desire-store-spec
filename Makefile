SCHEMA := schemas/desire-store/openapi.yaml

.DEFAULT_GOAL := help

.PHONY: help
help: ## Show the available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-14s %s\n", $$1, $$2}'

node_modules: package.json package-lock.json
	npm ci
	@touch node_modules

.PHONY: generate
generate: node_modules ## Compile main.tsp into $(SCHEMA)
	./build-schema.sh

.PHONY: build
build: generate ## Generate the schema and build the Go module
	go build ./...

.PHONY: lint
lint: node_modules ## Lint the OpenAPI schema with Spectral and the Go code with go vet
	npx spectral lint $(SCHEMA) --fail-severity warn
	go vet ./...

.PHONY: test
test: ## Run the Go tests
	go test ./...

.PHONY: verify-schema
verify-schema: generate ## Fail when the committed schema differs from the TypeSpec sources
	git diff --exit-code -- schemas/

.PHONY: install-hooks
install-hooks: ## Install the pre-commit and commit-msg hooks
	pre-commit install

.PHONY: clean
clean: ## Remove TypeSpec build output
	rm -rf tsp-output tsp-output-*
