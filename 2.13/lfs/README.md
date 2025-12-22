
# Building the LFS Plugin (lfs-2.13) on Ubuntu 18.04 / WSL2

This project builds with Buck. Newer Buck (2022.x) enforces stricter import rules and symlink handling; the steps below include the needed tweaks.

## Prerequisites
- OpenJDK 8
- curl, zip, unzip, git
- Buck available on PATH (`buck`), or a compatible wrapper/PEX

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
