# Development Base Container

This repository provides a streamlined development environment for Rust projects packaged in a Docker container. It creates a consistent, pre-configured environment with all necessary tools for Rust development, Kubernetes interaction, and database management.

## Features

- **Cross-platform support**: Build for both ARM64 (Apple Silicon) and AMD64 (Intel/AMD) architectures
- **Optimized image size**: Carefully designed multi-stage build process
- **Pre-configured Rust environment** with common tools:
  - Cargo extensions (cargo-chef, cargo-watch, cornucopia)
  - Rustfmt and Clippy
  - WebAssembly target support
- **Kubernetes tools**: kubectl, k9s, kind, k3d
- **Database tools**: PostgreSQL client, dbmate
- **Development utilities**: Git, Docker CLI, Mold (fast linker), Just, Direnv, Pulumi
- **Customizable user setup**: Non-root user with sudo access
- **Ready-to-use shell environment**: Zsh with Oh My Zsh

## Requirements

- Docker with buildx support
- [Just](https://github.com/casey/just) command runner

## Quick Start

- Clone this repository

```bash
git clone https://github.com/yourusername/development-base.git
cd development-base
```

- Build the image for your local platform

```bash
just docker-build-local
```

- Run a shell in the container

```bash
   just docker-shell
```

## Available Commands

View all available commands:

```bash
just docker-build
# Or set a variable for the image name and tag
just --image-tag latest --image-name auser/development-base docker-build
# Set the platform
just --platform linux/amd64,linux/arm64 docker-build
```

## Customization

To customize the container, you can:

- Add or remove tools in the `Dockerfile`
- Modify the `Justfile` to add or remove commands
