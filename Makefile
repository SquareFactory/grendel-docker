TAG_NAME = $(shell git describe --tags --abbrev=0 --exact-match 2>/dev/null)
TAG_NAME_DEV = $(shell git describe --tags --abbrev=0 2>/dev/null)
GIT_COMMIT = $(shell git rev-parse --short=7 HEAD)
VERSION = $(or $(TAG_NAME),$(and $(TAG_NAME_DEV),$(TAG_NAME_DEV)-dev),$(GIT_COMMIT))

.PHONY: docker
docker:
	@podman manifest rm ghcr.io/squarefactory/grendel:${VERSION} || true
	podman build \
		--manifest ghcr.io/squarefactory/grendel:${VERSION} \
		--platform=linux/amd64,linux/arm64/v8 \
		.
