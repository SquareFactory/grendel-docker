.PHONY: docker
docker:
	podman manifest rm ghcr.io/squarefactory/grendel:latest || true
	podman build \
		--manifest ghcr.io/squarefactory/grendel:latest \
		--jobs=2 --platform=linux/amd64,linux/arm64/v8 \
		-f Dockerfile .
