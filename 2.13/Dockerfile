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
    zip \
    unzip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create working directory
WORKDIR /workspace

# Install Buck (PEX) and make it executable
RUN curl -L https://github.com/facebook/buck/releases/download/v2022.05.05.01/buck.pex -o /usr/local/bin/buck \
    && chmod +x /usr/local/bin/buck

# Clone LFS plugin (stable-2.13) and bucklets, then link as per README
RUN git clone https://gerrit.googlesource.com/plugins/lfs -b stable-2.13 lfs-2.13 \
    && git clone https://gerrit.googlesource.com/bucklets \
    && cd lfs-2.13 \
    && ln -s ../bucklets . \
    && ln -s bucklets/buckversion .buckversion \
    && ln -s bucklets/watchmanconfig .watchmanconfig \
    && printf '\n[project]\n  read_only_paths = bucklets\n' >> .buckconfig \
    && printf 'download.MAVEN_CENTRAL=https://repo1.maven.org/maven2\n' > local.properties

# Patch bucklets for Buck 2022.x parser safety and PEX util import
RUN set -e; \
  cd /workspace/bucklets; \
  # gerrit_plugin.bucklet: allow_unsafe_import for multiprocessing/os and path usage
  sed -i "s/^\s*from multiprocessing import cpu_count//" gerrit_plugin.bucklet; \
  sed -i "s/^\s*from os import path,getcwd//" gerrit_plugin.bucklet; \
  awk '/target_suffix = '\''\)\:'\''/ && c==0 {print; print "  with allow_unsafe_import():\n    import multiprocessing\n    import os"; c=1; next} {print}' gerrit_plugin.bucklet > gerrit_plugin.bucklet.tmp && mv gerrit_plugin.bucklet.tmp gerrit_plugin.bucklet; \
  sed -i "s/ROOT = getcwd()/ROOT = os.getcwd()/" gerrit_plugin.bucklet; \
  sed -i "s/\bpath\./os.path./g" gerrit_plugin.bucklet; \
  sed -i "s/local_workers = cpu_count()/local_workers = multiprocessing.cpu_count()/" gerrit_plugin.bucklet; \
  # tools/download_file.py: ensure script dir on sys.path before importing util
  cd /workspace/bucklets/tools; \
  awk 'BEGIN{added=0} /from util import resolve_url/ && !added {print "import sys\nfrom os import path as _path_for_sys\nsys.path.insert(0, _path_for_sys.dirname(__file__))"; added=1} {print}' download_file.py > download_file.py.tmp && mv download_file.py.tmp download_file.py

# Remove unsupported java_test kwarg in plugin BUCK for current Buck
RUN sed -i "/source_under_test/d" /workspace/lfs-2.13/BUCK

# Build the plugin
RUN cd /workspace/lfs-2.13 \
    && buck kill || true \
    && buck build plugin

# Provide built artifact path
WORKDIR /workspace/lfs-2.13
CMD ["/bin/bash", "-lc", "ls -l buck-out/gen || true; echo 'Built plugin jar (if successful) is at buck-out/gen/lfs.jar'; bash"]
