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

### 2. /path/to/gerrit/etc/lfs.config

```
[s3]
    hostname = s3.amazonaws.com
    region = us-east-1
    bucket = my-lfs-bucket
    storageClass = REDUCED_REDUNDANCY
    expirationSeconds = 60
    disableSslVerify = true
```

**Note:** For security, place `s3.accessKey` and `s3.secretKey` in `/path/to/gerrit/etc/lfs.secure.config`:

```
[s3]
    accessKey = YOUR_ACCESS_KEY
    secretKey = YOUR_SECRET_KEY
```

**S3 Configuration Options:**
- `s3.hostname`: Custom hostname for S3 API server (default: AWS)
- `s3.region`: Amazon region where the S3 bucket resides
- `s3.bucket`: Name of the S3 storage bucket
- `s3.storageClass`: S3 storage class (default: `REDUCED_REDUNDANCY`)
- `s3.expirationSeconds`: Validity of signed requests in seconds (default: `60`)
- `s3.disableSslVerify`: Disable SSL verification (default: `false`)
- `s3.accessKey`: Amazon IAM access key (recommended in secure config)
- `s3.secretKey`: Amazon IAM secret key (recommended in secure config)

### 3. All-Projects/refs/meta/config/lfs.config

```
[lfs "test-repo"]
    enabled = true
    maxObjectSize = 1g
    backend = s3
[storage]
    backend = s3
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

# Verify LFS is configured
git ls-remote http://127.0.0.1:8080/a/test-repo

# Trace file types that will be stored on s3 backend
# Files will be stored on s3 server
git lfs track "*.bin"
git lfs track "*.dat"
git add .gitattributes
git commit -m "Configure Git LFS tracking with s3 backend"

# Push LFS files (will be stored on s3 server)
git add large-file.bin
git commit -m "Add large binary file (stored on s3 backend)"
git push origin HEAD:refs/for/master

# Verify LFS file was uploaded to s3 backend
# The file should be accessible on s3 server
git lfs ls-files
```

## Reference

- [dev-buck](https://gerrit-documentation.storage.googleapis.com/Documentation/2.13/dev-buck.html)
- [gerrit-ci-plugin-lfs](https://gerrit-ci.gerritforge.com/job/plugin-lfs-bazel-master/lastSuccessfulBuild/console)
- [gerrit-plugins](https://www.gerritcodereview.com/plugins.html)
- [git-lfs](https://git-lfs.com)
- [lfs-build](https://gerrit.googlesource.com/plugins/lfs/+/refs/heads/stable-2.13/src/main/resources/Documentation/build.md)
- [lfs-config](https://gerrit.googlesource.com/plugins/lfs/+/refs/heads/master/src/main/resources/Documentation/config.md)
- [minio-s3](https://github.com/craftslab/minio)
