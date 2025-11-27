# Use Ubuntu as base image (glibc >= 2.28 to satisfy Node from rules_nodejs)
FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$PATH

# Update system and install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    zip \
    unzip \
    wget \
    build-essential \
    ca-certificates \
    openjdk-11-jdk-headless \
    python3 \
    python3-distutils \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 16.x and npm from NodeSource
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash - \
    && apt-get install -y nodejs

# Ensure `python` points to Python 3 for Bazel builds on Ubuntu 18.04
RUN ln -sf /usr/bin/python3 /usr/bin/python

# Ensure `node` binary exists (Ubuntu 18.04 provides `nodejs`); skip if already present
RUN [ -e /usr/bin/node ] || ln -sf /usr/bin/nodejs /usr/bin/node

# Install Yarn 1.x for Bazel rules_nodejs (resolves @npm_* repos like rollup)
RUN npm install -g yarn@1.22.22

# Create working directory
WORKDIR /workspace

# Install Bazelisk (auto-selects correct Bazel version via Gerrit .bazelversion)
RUN curl -L https://github.com/bazelbuild/bazelisk/releases/download/v1.21.0/bazelisk-linux-amd64 -o /usr/local/bin/bazel \
    && chmod +x /usr/local/bin/bazel

# Clone Gerrit core (master) as in CI job
RUN git clone https://gerrit.googlesource.com/gerrit -b master

# Clone LFS plugin (master) under Gerrit plugins as in CI
RUN cd gerrit && \
    git clone https://gerrit.googlesource.com/plugins/lfs -b master plugins/lfs

# Initialize Gerrit submodules similar to CI
RUN cd gerrit && git submodule update --init --recursive

# Build LFS plugin with Bazel (per plugin build.md)
WORKDIR /workspace/gerrit
RUN bazel sync --configure \
    && bazel query '@@all//...' || true \
    && bazel build plugins/lfs

# Export built plugin to a stable location
RUN mkdir -p /workspace/output \
    && cp bazel-bin/plugins/lfs/lfs.jar /workspace/output/

# Set working directory to gerrit
WORKDIR /workspace/gerrit

# Expose common Gerrit ports
EXPOSE 8080 29418

# Default command
CMD ["/bin/bash"]
