
# Building the LFS Plugin (lfs-2.13) on Ubuntu 18.04 / WSL2

This project builds with Buck. Newer Buck (2022.x) enforces stricter import rules and symlink handling; the steps below include the needed tweaks.

## Prerequisites
- OpenJDK 8
- curl, zip, unzip, git
- Buck (install via .deb or PEX below)

## Install Buck
You can install Buck either from the Debian package or as a standalone PEX.

Option A — Debian package (recommended on Ubuntu 18.04):
```bash
sudo apt-get update && sudo apt-get install -y curl
curl -fL https://github.com/facebook/buck/releases/download/v2022.05.05.01/buck.2022.05.05.01_all.deb -o /tmp/buck.deb
sudo dpkg -i /tmp/buck.deb || sudo apt-get -f install -y
sudo dpkg -i /tmp/buck.deb
rm -f /tmp/buck.deb
buck --version
```

Option B — PEX (single-file binary):
```bash
sudo curl -fL https://github.com/facebook/buck/releases/download/v2022.05.05.01/buck.pex -o /usr/local/bin/buck
sudo chmod +x /usr/local/bin/buck
buck --version
```

## One-time setup in the plugin root
```bash
sudo apt-get update
sudo apt-get install -y openjdk-8-jdk curl zip unzip git

# In /home/lemonjia/my-tmp/lfs-2.13
git clone https://gerrit.googlesource.com/bucklets ../bucklets || true
ln -s ../bucklets .
ln -s bucklets/buckversion .buckversion
ln -s bucklets/watchmanconfig .watchmanconfig

# Let Buck accept the symlinked bucklets directory
printf '\n[project]\n  read_only_paths = bucklets\n' >> .buckconfig

# (Optional) force HTTPS for Maven Central if behind proxies or to avoid bad mirrors
cat > local.properties <<'EOF'
download.MAVEN_CENTRAL=https://repo1.maven.org/maven2
EOF
```

## Buck compatibility fixes applied
- `bucklets/gerrit_plugin.bucklet`: use `allow_unsafe_import()` for `multiprocessing` and `os`.
- `BUCK`: removed unsupported `source_under_test` arg in `java_test` for current Buck.

## Version Configuration
The plugin version is defined in the `VERSION` file. To change the version:
```bash
# Edit VERSION file and set PLUGIN_VERSION
echo "PLUGIN_VERSION = 'v2.13.9-20251230'" > VERSION
```
The version will be included in the manifest as `Implementation-Version` when building the plugin.

## Build
```bash
# From /home/lemonjia/my-tmp/lfs-2.13
buck kill  # optional but helps after config changes
buck build plugin
```

The jar will be at `buck-out/gen/lfs.jar` (standalone mode). If building inside a Gerrit tree, it would land under `buck-out/gen/plugins/lfs/lfs.jar`.

## Troubleshooting
- If Buck still complains about symlinks, replace the symlink with a copy: `rm bucklets && cp -a ../bucklets ./bucklets`.
- If downloads fail with SHA mismatches, clear cached artifacts in `~/.gerritcodereview/buck-cache/downloaded-artifacts` and ensure `download.MAVEN_CENTRAL` is set to HTTPS.
- Watchman is optional; the “Not using buckd because watchman isn't installed.” message is harmless.
