# gerritlfs

## Overview

- [2.13](https://github.com/craftslab/gerritlfs/tree/main/2.13) - Gerrit 2.13 version build files
- [3.2](https://github.com/craftslab/gerritlfs/tree/main/3.2) - Gerrit 3.2 version build files

## Config

### 1. /path/to/gerrit/etc/gerrit.config

```
[plugin "lfs"]
    enabled = true
[lfs]
    plugin = lfs
```

### 2. All-Projects/refs/meta/config/lfs.config

```
[lfs "test-repo"]
    enabled = true
    maxObjectSize = 500m
```

### 3. test-repo

```bash
# Clone repo
git clone http://127.0.0.1:8080/a/test-repo
cd test-repo

# Configure LFS
git lfs install
git config lfs.url http://127.0.0.1:8080/a/test-repo/info/lfs
git config credential.helper store
git ls-remote http://127.0.0.1:8080/a/test-repo

# Trace file types
git lfs track "*.bin"
git lfs track "*.dat"
git add .gitattributes
git commit -m "Configure Git LFS tracking"

# Push LFS files
git add large-file.bin
git commit -m "Add large binary file"
git push origin HEAD:refs/for/master
```

## Reference

- [dev-buck](https://gerrit-documentation.storage.googleapis.com/Documentation/2.13/dev-buck.html)
- [gerrit-ci-plugin-lfs](https://gerrit-ci.gerritforge.com/job/plugin-lfs-bazel-master/lastSuccessfulBuild/console)
- [gerrit-plugins](https://www.gerritcodereview.com/plugins.html)
- [lfs-build](https://gerrit.googlesource.com/plugins/lfs/+/refs/heads/stable-2.13/src/main/resources/Documentation/build.md)
- [lfs-config](https://gerrit.googlesource.com/plugins/lfs/+/refs/heads/master/src/main/resources/Documentation/config.md)
