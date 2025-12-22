# Use Ubuntu as base image
FROM ubuntu:18.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV PATH=/usr/local/bin:$PATH

# Update system and install dependencies
RUN apt-get update && apt-get install -y \
    openjdk-8-jdk \
    curl \
    git \
    python \
    python3 \
    python3-distutils \
    zip \
    unzip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create working directory
WORKDIR /workspace

# Install Buck via .deb and verify installation
RUN set -eux; \
    apt-get update && apt-get install -y python3-distutils; \
    BUCK_DEB_URL="https://github.com/facebook/buck/releases/download/v2022.05.05.01/buck.2022.05.05.01_all.deb"; \
    curl -fL "$BUCK_DEB_URL" -o /tmp/buck.deb; \
    dpkg -i /tmp/buck.deb || (apt-get -f install -y && dpkg -i /tmp/buck.deb); \
    rm -f /tmp/buck.deb; \
    buck --version

# Use local lfs and bucklets directories from build context
COPY lfs /workspace/lfs-2.13
COPY bucklets /workspace/bucklets

# Link bucklets into plugin dir and set config overrides
RUN set -eux; \
    cd /workspace/lfs-2.13; \
    ln -s ../bucklets ./bucklets || true; \
    ln -s bucklets/buckversion .buckversion || true; \
    ln -s bucklets/watchmanconfig .watchmanconfig || true;

# Build the plugin
RUN cd /workspace/lfs-2.13 \
    && buck kill || true \
    && buck build plugin

# Provide built artifact path
WORKDIR /workspace/lfs-2.13
CMD ["/bin/bash", "-lc", "ls -l buck-out/gen || true; echo 'Built plugin jar (if successful) is at buck-out/gen/lfs.jar'; bash"]
