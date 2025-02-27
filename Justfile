image_name := "auser/development-base"
image_tag := "latest"
platform := "linux/amd64,linux/arm64"
flavor := "rust"

# List all just commands
default:
  just --list

# Ensure buildx is properly configured
setup-buildx:
  docker buildx create --name multiplatform-builder --use
  docker buildx inspect --bootstrap

# Build the docker image
docker-build: setup-buildx
  docker buildx build --platform {{platform}} -t {{image_name}}:{{image_tag}} --file {{flavor}}/Dockerfile .

# Run the docker image
docker-run:
  docker run -it {{image_name}}:{{image_tag}}