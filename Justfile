image_name := "auser/development-base"
image_tag := "latest"
platform := "linux/amd64,linux/arm64"
flavor := "rust"

# List all just commands
default:
  just --list

# Check if the multiplatform-builder exists
builder-exists:
  #!/usr/bin/env bash
  if docker buildx inspect multiplatform-builder > /dev/null 2>&1; then
    exit 0
  else
    exit 1
  fi

# Create a new buildx builder
create-builder:
  docker buildx create --name multiplatform-builder --use

# Use existing builder
use-builder:
  docker buildx use multiplatform-builder

# Ensure buildx is properly configured
setup-buildx:
  #!/usr/bin/env bash
  if docker buildx inspect multiplatform-builder > /dev/null 2>&1; then
    docker buildx use multiplatform-builder
  else
    docker buildx create --name multiplatform-builder --use
  fi
  docker buildx inspect --bootstrap

# Build multi-platform and push to registry
docker-build-push: setup-buildx
  docker buildx build --platform {{platform}} -t {{image_name}}:{{image_tag}} --file {{flavor}}/Dockerfile --push .

# Build for local platform only and load into Docker (for arm64/Apple Silicon)
docker-build-arm64: setup-buildx
  docker buildx build --platform linux/arm64 -t {{image_name}}:{{image_tag}} --file {{flavor}}/Dockerfile --load .

# Build for local platform only and load into Docker (for amd64/Intel)
docker-build-amd64: setup-buildx
  docker buildx build --platform linux/amd64 -t {{image_name}}:{{image_tag}} --file {{flavor}}/Dockerfile --load .

# Determine current architecture and build for it
docker-build-local:
  #!/usr/bin/env bash
  ARCH=$(docker info -f '{{{{.Architecture}}}}')
  if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    just docker-build-arm64
  else
    just docker-build-amd64
  fi

# Build for local testing (cache only, not usable directly)
docker-build: setup-buildx
  docker buildx build --platform {{platform}} -t {{image_name}}:{{image_tag}} --file {{flavor}}/Dockerfile .

# Run the docker image (only works after docker-build-local)
docker-run:
  docker run -it {{image_name}}:{{image_tag}}

# Run interactive shell in the docker image
docker-shell:
  docker run -it --rm {{image_name}}:{{image_tag}}