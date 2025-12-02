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
    maxObjectSize = 1g
    backend = remote
[storage]
    backend = remote
[remote "http-backend"]
    url = https://lfs-server.example.com
    username = myuser
    password = mypass
    disableSslVerify = true
[remote "ssh-backend"]
    sshHost = lfs-server.example.com
    sshPort = 22
    sshUser = git
    sshKeyFile = /path/to/private/key
```

### 3. test-repo

```bash
# Clone repo via HTTP
git clone http://127.0.0.1:8080/a/test-repo
cd test-repo

# Configure LFS to use HTTP protocol
git lfs install
git config lfs.url http://127.0.0.1:8080/a/test-repo/info/lfs
git config credential.helper store

# Verify LFS is configured
git ls-remote http://127.0.0.1:8080/a/test-repo

# Trace file types that will be stored on remote backend
# Files will be stored on the remote server via HTTP backend
git lfs track "*.bin"
git lfs track "*.dat"
git add .gitattributes
git commit -m "Configure Git LFS tracking with HTTP remote backend"

# Push LFS files (will be stored on remote server via HTTP)
git add large-file.bin
git commit -m "Add large binary file (stored on HTTP remote backend)"
git push origin HEAD:refs/for/master

# Verify LFS file was uploaded to HTTP remote backend
# The file should be accessible via HTTP on the remote server
git lfs ls-files
```

```bash
# Clone repo via SSH
git clone ssh://user@127.0.0.1:29418/test-repo
cd test-repo

# Configure LFS to use SSH protocol
git lfs install
git config lfs.url ssh://user@127.0.0.1:29418/test-repo/info/lfs
git config credential.helper store

# Verify LFS is configured
git ls-remote ssh://user@127.0.0.1:29418/test-repo

# Trace file types that will be stored on SSH remote backend
# Files will be stored on the remote server via SSH backend
git lfs track "*.bin"
git lfs track "*.dat"
git add .gitattributes
git commit -m "Configure Git LFS tracking with SSH remote backend"

# Push LFS files (will be stored on remote server via SSH)
git add large-file.bin
git commit -m "Add large binary file (stored on SSH remote backend)"
git push origin HEAD:refs/for/master

# Verify LFS file was uploaded to SSH remote backend
# The file should be accessible via SSH on the remote server
git lfs ls-files
```

**Backend Selection:**

The `backend = remote` setting automatically selects between HTTP and SSH remote backends based on available backends. To explicitly control backend selection, update the project configuration in `All-Projects/refs/meta/config/lfs.config`:

```
[lfs "test-repo"]
    enabled = true
    maxObjectSize = 1g
    backend = remote          # Automatic selection (prefers HTTP if both available)
    # OR
    backend = remote:http     # Explicitly use HTTP/HTTPS remote backend
    # OR
    backend = remote:ssh      # Explicitly use SSH remote backend
    # OR
    backend = http-backend    # Use specific named HTTP backend
    # OR
    backend = ssh-backend     # Use specific named SSH backend
```

## Reference

- [dev-buck](https://gerrit-documentation.storage.googleapis.com/Documentation/2.13/dev-buck.html)
- [gerrit-ci-plugin-lfs](https://gerrit-ci.gerritforge.com/job/plugin-lfs-bazel-master/lastSuccessfulBuild/console)
- [gerrit-plugins](https://www.gerritcodereview.com/plugins.html)
- [git-lfs](https://git-lfs.com)
- [lfs-build](https://gerrit.googlesource.com/plugins/lfs/+/refs/heads/stable-2.13/src/main/resources/Documentation/build.md)
- [lfs-config](https://gerrit.googlesource.com/plugins/lfs/+/refs/heads/master/src/main/resources/Documentation/config.md)
