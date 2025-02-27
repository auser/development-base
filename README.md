# Development Base

This is a base image for development purposes. It is a simple image that is used to build and run the project.

## Building the image

```bash
just docker-build
# Or set a variable for the image name and tag
just --image-tag latest --image-name auser/development-base docker-build
# Set the platform
just --platform linux/amd64,linux/arm64 docker-build
```

