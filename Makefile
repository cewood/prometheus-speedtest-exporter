ARCH               = $(or $(shell printenv ARCH),$(shell echo linux/amd64,linux/arm64,linux/arm/v6,linux/arm/v7))
BUILD_FLAGS        = $(or $(shell printenv BUILD_FLAGS),--pull)
CREATED            = $(or $(shell printenv CREATED),$(shell date --rfc-3339=seconds))
GIT_REVISION       = $(or $(shell printenv GIT_REVISION), $(shell git describe --match= --always --abbrev=7 --dirty))
IMAGE              = $(or $(shell printenv IMAGE),docker.io/cewood/prometheus-speedtest-exporter)
IMAGE_TAG          = $(or $(shell printenv IMAGE_TAG),${TAG_REVISION})
TAG_REVISION       = $(or $(shell printenv TAG_REVISION),${GIT_REVISION})



.PHONY: shellcheck
shellcheck:
	docker \
	  run \
	  --rm \
	  -i \
	  -v ${PWD}:/mnt \
	  koalaman/shellcheck:v0.7.2 \
	  *.sh

.PHONY: hadolint
hadolint:
	docker \
	  run \
	  --rm \
	  -i \
	  hadolint/hadolint:v2.5.0 \
	  < Dockerfile

.PHONY: trivy
trivy:
	docker \
	  run \
	  --rm \
	  -i \
	  -v /var/run/docker.sock:/var/run/docker.sock:ro \
          -v ${PWD}/.cache:/root/.cache/ \
	  aquasec/trivy:0.18.3 \
	  --severity HIGH,CRITICAL \
	  ${IMAGE}:${IMAGE_TAG}

.PHONY: dive
dive:
	docker \
	  run \
	  --rm \
	  -i \
	  -v /var/run/docker.sock:/var/run/docker.sock:ro \
	  -e CI=true \
	  wagoodman/dive:v0.10.0 \
	  ${IMAGE}:${IMAGE_TAG}

.PHONY: build
build:
	DOCKER_CLI_EXPERIMENTAL=enabled \
	docker \
	  buildx build \
	  ${BUILD_FLAGS} \
	  --build-arg CREATED="${CREATED}" \
	  --build-arg REVISION="${GIT_REVISION}" \
	  --platform ${ARCH} \
	  --tag ${IMAGE}:${IMAGE_TAG} \
	  -f Dockerfile \
	  .

.PHONY: load
load:
	$(MAKE) build BUILD_FLAGS=--load ARCH=linux/amd64

.PHONY: inspect
inspect:
	docker inspect ${IMAGE}:${IMAGE_TAG}

.PHONY: binfmt-setup
binfmt-setup:
	docker \
	  run \
	  --rm \
	  --privileged \
	  docker/binfmt:66f9012c56a8316f9244ffd7622d7c21c1f6f28d

.PHONY: buildx-setup
buildx-setup:
	DOCKER_CLI_EXPERIMENTAL=enabled \
	docker \
	  buildx \
	  create \
	  --use \
	  --name multiarch

.PHONY: ci
ci:
	$(MAKE) build BUILD_FLAGS=$(if ${GITHUB_REF},--push,--pull)
	$(MAKE) build BUILD_FLAGS=$(if ${GITHUB_REF},--push,--pull) TAG_REVISION=latest
	$(if $(findstring refs/tags,${GITHUB_REF}),$(MAKE) build BUILD_FLAGS=--push TAG_REVISION=$${GITHUB_REF#refs/tags/})
