# ai-defense-cli — build orchestration
#
# Two CLI build modes:
#   go    — Go only (stub embedded Python; ai-bom needs AID_CLI_PYTHON or fails clearly)
#   full  — Go + relocatable CPython + cisco-aibom embedded (release binaries)
#
# Examples:
#   make build              # same as make build-go
#   make build BUILD_MODE=full
#   make build-go test vet
#   make bundle             # build Python embed artifacts (required before build-embed)
#   make build-embed

.DEFAULT_GOAL := help

BINARY_NAME   ?= aid-cisco-cli
BIN_DIR       ?= bin
MODULE        ?= github.com/cisco-ai-defense/ai-defense-cli
BUILD_MODE    ?= go

VERSION       ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo dev)
COMMIT        ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo unknown)
BUILD_DATE    ?= $(shell date -u +%Y-%m-%dT%H:%M:%SZ)

GO            ?= go
GOOS          ?= $(shell $(GO) env GOOS)
GOARCH        ?= $(shell $(GO) env GOARCH)
CGO_ENABLED   ?= 0

EMBED_PKG     := ./internal/embedded/python
EMBED_BIN_DIR := internal/embedded/python/bin
BUNDLE_TAR    := $(EMBED_BIN_DIR)/aid-py-bundle.tar.gz
BUNDLE_ID     := $(EMBED_BIN_DIR)/aid-py-bundle.id

LDFLAGS := -s -w \
	-X $(MODULE)/cmd.version=$(VERSION) \
	-X $(MODULE)/cmd.commit=$(COMMIT) \
	-X $(MODULE)/cmd.date=$(BUILD_DATE)

.PHONY: help build build-go build-embed bundle bundle-check test vet fmt clean

help: ## Show targets
	@printf "ai-defense-cli Makefile\n\n"
	@printf "Build modes (BUILD_MODE):\n"
	@printf "  go   — Go CLI only; embedded Python stub (!embed_python)\n"
	@printf "  full — Go + embedded CPython/aibom (-tags embed_python); run 'make bundle' first\n\n"
	@grep -E '^[a-zA-Z0-9_.-]+:.*##' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*## "}; {printf "  %-16s %s\n", $$1, $$2}'

build: ## Build CLI (BUILD_MODE=go|full, default go)
ifeq ($(BUILD_MODE),full)
	$(MAKE) build-embed
else ifeq ($(BUILD_MODE),go)
	$(MAKE) build-go
else
	$(error BUILD_MODE must be 'go' or 'full', got '$(BUILD_MODE)')
endif

build-go: ## Build Go-only CLI (no embedded Python bundle)
	@test -f go.mod || (echo "go.mod not found — migrate CLI source first" && exit 1)
	@mkdir -p $(BIN_DIR)
	CGO_ENABLED=$(CGO_ENABLED) GOOS=$(GOOS) GOARCH=$(GOARCH) $(GO) build \
		-ldflags "$(LDFLAGS)" \
		-o $(BIN_DIR)/$(BINARY_NAME) .
	@printf "Built $(BIN_DIR)/$(BINARY_NAME) (go-only / stub python)\n"

build-embed: bundle-check ## Build CLI with embedded CPython + cisco-aibom
	@test -f go.mod || (echo "go.mod not found — migrate CLI source first" && exit 1)
	@mkdir -p $(BIN_DIR)
	CGO_ENABLED=$(CGO_ENABLED) GOOS=$(GOOS) GOARCH=$(GOARCH) $(GO) build \
		-tags embed_python \
		-ldflags "$(LDFLAGS)" \
		-o $(BIN_DIR)/$(BINARY_NAME) .
	@printf "Built $(BIN_DIR)/$(BINARY_NAME) (embedded python + aibom)\n"

bundle: ## Build relocatable CPython + cisco-aibom embed artifacts
	@test -f scripts/build-python-bundle.sh || \
		(echo "scripts/build-python-bundle.sh missing" && exit 1)
	@chmod +x scripts/build-python-bundle.sh
	./scripts/build-python-bundle.sh

bundle-check:
	@test -f $(BUNDLE_TAR) || (echo "Missing $(BUNDLE_TAR) — run: make bundle" && exit 1)
	@test -f $(BUNDLE_ID) || (echo "Missing $(BUNDLE_ID) — run: make bundle" && exit 1)

test: ## Run tests (stub python; no embed bundle required)
	@test -f go.mod || (echo "go.mod not found — migrate CLI source first" && exit 1)
	$(GO) test ./...

vet: ## Run go vet
	@test -f go.mod || (echo "go.mod not found — migrate CLI source first" && exit 1)
	$(GO) vet ./...

fmt: ## gofmt all Go files
	@gofmt -w $$(find . -name '*.go' -not -path './vendor/*')

clean: ## Remove build outputs
	rm -rf $(BIN_DIR)/$(BINARY_NAME)
	rm -rf $(EMBED_BIN_DIR)/aid-py-bundle.tar.gz $(EMBED_BIN_DIR)/aid-py-bundle.id
	$(GO) clean -cache -testcache 2>/dev/null || true
