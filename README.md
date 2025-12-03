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

**For MinIO (S3-compatible)**

```
[s3]
    hostname = localhost:9000
    region = us-east-1
    bucket = my-lfs-bucket
    storageClass = REDUCED_REDUNDANCY
    expirationSeconds = 60
    disableSslVerify = true
```

**For AWS S3**

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

**MinIO Configuration Options**
- `s3.hostname`: Use `localhost:9000` for local MinIO deployment, or the actual hostname/IP if MinIO is on a different host
- `s3.region`: Can be any value (e.g., `us-east-1`) as MinIO is S3-compatible but doesn't enforce AWS regions
- `s3.bucket`: Must match the bucket name created in MinIO
- `s3.disableSslVerify`: Set to `true` for local MinIO deployments without SSL certificates

**S3 Configuration Options**
- `s3.hostname`: Custom hostname for S3 API server
  - For MinIO: Use `localhost:9000` (or your MinIO server hostname:port)
  - For AWS: Use `s3.amazonaws.com` (default)
- `s3.region`: Amazon region where the S3 bucket resides (for MinIO, any value is acceptable)
- `s3.bucket`: Name of the S3 storage bucket (must exist in MinIO/AWS)
- `s3.storageClass`: S3 storage class (default: `REDUCED_REDUNDANCY`)
- `s3.expirationSeconds`: Validity of signed requests in seconds (default: `60`)
- `s3.disableSslVerify`: Disable SSL verification (default: `false`, set to `true` for local MinIO without SSL)
- `s3.accessKey`: Access key (MinIO access key or Amazon IAM access key, recommended in secure config)
- `s3.secretKey`: Secret key (MinIO secret key or Amazon IAM secret key, recommended in secure config)

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

# Trace file types that will be stored on S3 backend (MinIO or AWS S3)
# Files will be stored on S3-compatible storage server
git lfs track "*.bin"
git lfs track "*.dat"
git add .gitattributes
git commit -m "Configure Git LFS tracking with S3 backend"

# Push LFS files (will be stored on S3-compatible storage server)
git add large-file.bin
git commit -m "Add large binary file (stored on S3 backend)"
git push origin HEAD:refs/for/master

# Verify LFS file was uploaded to S3 backend
# The file should be accessible on S3 server (check MinIO Console at http://localhost:9001)
git lfs ls-files
```

## Storage

This guide uses MinIO as an S3-compatible backend for Gerrit LFS. MinIO is a high-performance, S3-compatible object storage solution.

### Deploy MinIO

Run MinIO using the `craftslab/minio:latest` Docker image:

```bash
docker run -d \
  --name minio \
  -p 9000:9000 \
  -p 9001:9001 \
  -v /path/to/minio/data:/tmp/minio \
  craftslab/minio:latest server /tmp/minio --console-address :9001
```

**Credentials:**
- Access Key: `minioadmin`
- Secret Key: `minioadmin`

**Ports:**
- `9000`: S3 API endpoint (used by Gerrit LFS)
- `9001`: MinIO Console (web-based object browser)

### Create Credentials

1. **Access MinIO Console:**
    - Open your browser to `http://localhost:9001`
    - Login with default credentials: `minioadmin` / `minioadmin`

2. **Create a Bucket:**
    - Navigate to Buckets section
    - Create a new bucket (e.g., `my-lfs-bucket`)

3. **Create Access Key (Recommended for Production):**
    - Navigate to Access Keys section
    - Create a new access key with appropriate permissions
    - Save the Access Key and Secret Key for use in Gerrit configuration

### Test Connectivity

You can test MinIO using the MinIO Client (`mc`):

```bash
mc alias set local http://localhost:9000 minioadmin minioadmin
mc admin info local
mc mb local/my-lfs-bucket
mc ls local/
```

For more information, refer to the [MinIO Quickstart Guide](https://github.com/craftslab/minio).

## Reference

- [dev-buck](https://gerrit-documentation.storage.googleapis.com/Documentation/2.13/dev-buck.html)
- [gerrit-ci-plugin-lfs](https://gerrit-ci.gerritforge.com/job/plugin-lfs-bazel-master/lastSuccessfulBuild/console)
- [gerrit-plugins](https://www.gerritcodereview.com/plugins.html)
- [git-lfs](https://git-lfs.com)
- [lfs-build](https://gerrit.googlesource.com/plugins/lfs/+/refs/heads/stable-2.13/src/main/resources/Documentation/build.md)
- [lfs-config](https://gerrit.googlesource.com/plugins/lfs/+/refs/heads/master/src/main/resources/Documentation/config.md)
- [minio-s3](https://github.com/craftslab/minio)
