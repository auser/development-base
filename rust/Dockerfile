# Builder stage for all cargo installations
FROM rust:slim-bookworm AS builder

# Configure apt and install minimal build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev \
    curl \
    wget \
    xz-utils \
    build-essential \
    libssl-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Install Rust tools
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -y | sh

# Download and prepare cargo-watch
RUN curl https://github.com/watchexec/cargo-watch/releases/download/v8.5.2/cargo-watch-v8.5.2-aarch64-apple-darwin.tar.xz -L -o cargo-watch.tar.xz \
    && tar -xf cargo-watch.tar.xz \
    && mv cargo-watch-v8.5.2-aarch64-apple-darwin/cargo-watch /home \
    && rm -rf cargo-watch.tar.xz cargo-watch-v8.5.2-aarch64-apple-darwin

# Install cargo tools with sparse protocol
RUN CARGO_REGISTRIES_CRATES_IO_PROTOCOL=sparse cargo install cornucopia --no-default-features
RUN CARGO_REGISTRIES_CRATES_IO_PROTOCOL=sparse cargo install cargo-chef --locked --no-default-features

# Final stage
FROM rust:slim-bookworm AS final

ARG CLOAK_VERSION=1.19.4
ARG DBMATE_VERSION=2.7.0
ARG MOLD_VERSION=2.30.0
ARG EARTHLY_VERSION=0.8.9
ARG DOCKER_COMPOSE_VERSION=2.23.0
ARG K9S_VERSION=0.32.4
ARG ARCH=aarch64
ARG KIND_VERSION=0.17.0

# User setup
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

ENV DEBIAN_FRONTEND=noninteractive
ENV CARGO_HOME=/usr/local/cargo
ENV RUSTUP_HOME=/usr/local/rustup
ENV PATH=/usr/local/cargo/bin:$PATH

# Install necessary packages in a single RUN to reduce layers
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    wget \
    ssh \
    sudo \
    jq \
    gnupg \
    ca-certificates \
    postgresql-client \
    npm \
    nodejs \
    zsh \
    python3-pip \
    libpq-dev \
    # Minimal build essentials for rust
    gcc \
    libc6-dev \
    pkg-config \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/* \
    # Create a non-root user
    && groupadd --gid $USER_GID $USERNAME \
    && useradd -s /usr/bin/zsh --uid $USER_UID --gid $USER_GID -m $USERNAME -d /home/$USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    # Rust setup
    && rustup component add rustfmt clippy \
    && rustup target add wasm32-unknown-unknown

# Install Docker for Earthly in a single layer
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && chmod a+r /etc/apt/keyrings/docker.gpg \
    && echo "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
       "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
       tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y --no-install-recommends docker-ce-cli \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Install tools in a single layer to minimize size
RUN curl -fsSL -o /usr/local/bin/dbmate https://github.com/amacneil/dbmate/releases/latest/download/dbmate-linux-$(dpkg --print-architecture) \
    && chmod +x /usr/local/bin/dbmate \
    # Mold
    && curl -OL https://github.com/rui314/mold/releases/download/v$MOLD_VERSION/mold-$MOLD_VERSION-$ARCH-linux.tar.gz \
    && tar -xf mold-$MOLD_VERSION-$ARCH-linux.tar.gz \
    && mv ./mold-$MOLD_VERSION-$ARCH-linux/bin/mold /usr/bin/ \
    && mv ./mold-$MOLD_VERSION-$ARCH-linux/lib/mold/mold-wrapper.so /usr/bin/ \
    && rm -rf mold-$MOLD_VERSION-$ARCH-linux.tar.gz ./mold-$MOLD_VERSION-$ARCH-linux \
    # Docker Compose
    && curl -L https://github.com/docker/compose/releases/download/v$DOCKER_COMPOSE_VERSION/docker-compose-linux-$ARCH -o /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/docker-compose \
    # K9s
    && curl -L -s https://github.com/derailed/k9s/releases/download/v$K9S_VERSION/k9s_Linux_$(dpkg --print-architecture).tar.gz | tar xz -C /tmp \
    && mv /tmp/k9s /usr/bin \
    # Kind
    && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v$KIND_VERSION/kind-linux-$(dpkg --print-architecture) \
    && chmod +x ./kind \
    && mv ./kind /usr/local/bin/kind \
    # k3d
    && curl -s https://raw.githubusercontent.com/rancher/k3d/main/install.sh | USE_SUDO=false K3D_INSTALL_DIR=/usr/local/bin bash \
    # Kubectl
    && curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubectl" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
    && rm kubectl \
    # Just
    && curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin \
    # Direnv
    && curl -sfL https://direnv.net/install.sh | bash

# Copy binaries from builder stage
COPY --from=builder /home/cargo-watch $CARGO_HOME/bin/
COPY --from=builder /usr/local/cargo/bin/cargo-chef $CARGO_HOME/bin/
COPY --from=builder /usr/local/cargo/bin/cornucopia $CARGO_HOME/bin/

# Switch to non-root user for final layer
USER $USERNAME
WORKDIR /home/$USERNAME

# Install Oh My Zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Install Pulumi as non-root user
RUN curl -fsSL https://get.pulumi.com | sudo -E bash - \
    && sudo chown -R $USERNAME:$USERNAME /home/$USERNAME/.pulumi

# Set entrypoint to zsh
ENTRYPOINT ["/usr/bin/zsh"]

