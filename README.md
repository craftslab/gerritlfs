# gerritlfs

## Overview

- [2.13](https://github.com/craftslab/gerritlfs/tree/main/2.13) - Gerrit 2.13 version build files
- [3.2](https://github.com/craftslab/gerritlfs/tree/main/3.2) - Gerrit 3.2 version build files

## Prerequisites

### Install Git LFS

Git LFS must be installed before using this plugin. If you encounter the error:
```
fatal: 'lfs' appears to be a git command, but we were not able to execute it. Maybe git-lfs is broken?
```

Install Git LFS on Ubuntu using one of the following methods:

**Option 1: Using apt (Recommended for Ubuntu 24.04)**

```bash
# Update package list
sudo apt update

# Install git-lfs
sudo apt install git-lfs

# Initialize Git LFS
git lfs install
```

**Option 2: Using the official Git LFS repository**

```bash
# Add the Git LFS repository
curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash

# Install git-lfs
sudo apt install git-lfs

# Initialize Git LFS
git lfs install
```

After installation, verify it works:

```bash
git lfs version
```

You should see output like `git-lfs/3.x.x`.

**Note:** The `git lfs install` command sets up Git LFS hooks in your Git configuration. You only need to run it once per user account.

## Installation

### Build the LFS Plugin

The LFS plugin must be built and installed on your Gerrit server before it can be used. Choose the build method based on your Gerrit version:

#### For Gerrit 3.2

1. **Build the plugin using Docker:**

```bash
cd 3.2
./build.sh
```

This will create a Docker image `gerrit-plugins-lfs:3.2` containing the built plugin.

2. **Extract the lfs.jar from the Docker container:**

```bash
# Create a temporary container from the image
docker create --name temp-container gerrit-plugins-lfs:3.2

# Copy the lfs.jar from the container
docker cp temp-container:/workspace/output/lfs.jar ./lfs.jar

# Remove the temporary container
docker rm temp-container
```

#### For Gerrit 2.13

1. **Build the plugin using Docker:**

```bash
cd 2.13
./build.sh
```

This will create a Docker image `gerrit-plugins-lfs:2.13` containing the built plugin.

2. **Extract the lfs.jar from the Docker container:**

```bash
# Create a temporary container from the image
docker create --name temp-container gerrit-plugins-lfs:2.13

# Copy the lfs.jar from the container
# Note: For 2.13, the JAR location may vary. Check the container:
docker cp temp-container:/workspace/gerrit/plugins/lfs/lfs.jar ./lfs.jar

# Or if built with Buck:
docker cp temp-container:/workspace/gerrit/buck-out/gen/plugins/lfs/lfs.jar ./lfs.jar

# Remove the temporary container
docker rm temp-container
```

### Install the Plugin on Gerrit Server

1. **Copy lfs.jar to the Gerrit plugins directory:**

```bash
# Copy the built lfs.jar to your Gerrit installation
cp lfs.jar /path/to/gerrit/plugins/lfs.jar

# Ensure proper permissions
chown gerrit:gerrit /path/to/gerrit/plugins/lfs.jar
chmod 644 /path/to/gerrit/plugins/lfs.jar
```

2. **Restart Gerrit:**

```bash
# Restart your Gerrit server to load the plugin
# The exact command depends on your Gerrit installation method
systemctl restart gerrit
# OR
/path/to/gerrit/bin/gerrit.sh restart
```

3. **Verify the plugin is loaded:**

Check the Gerrit logs or web interface to confirm the LFS plugin is loaded. You should see the plugin listed in the Gerrit plugins page or in the startup logs.

**Note:** The plugin must be installed before configuring it. After installation, proceed to the [Config](#config) section to configure the plugin.

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
[s3 "minio"]
    hostname = localhost:9000
    region = us-east-1
    bucket = gerritlfs
    storageClass = REDUCED_REDUNDANCY
    expirationSeconds = 60
    disableSslVerify = true
```

**For AWS S3**

```
[s3 "aws"]
    hostname = s3.amazonaws.com
    region = us-east-1
    bucket = my-lfs-bucket
    storageClass = REDUCED_REDUNDANCY
    expirationSeconds = 60
    disableSslVerify = true
```

**Note:** For security, place `s3.accessKey` and `s3.secretKey` in `/path/to/gerrit/etc/lfs.secure.config`:

```
[s3 "minio]
    accessKey = YOUR_ACCESS_KEY
    secretKey = YOUR_SECRET_KEY
```

**MinIO Configuration Options**
- `s3.hostname`: Use `hostname:port` or `ip:port` format
  - **Important:** Do NOT include `http://` or `https://` protocol prefix
  - The AWS S3 SDK defaults to HTTPS, so ensure MinIO is configured with HTTPS (see [Generate SSL Certificates](#generate-ssl-certificates))
- `s3.region`: Can be any value (e.g., `us-east-1`) as MinIO is S3-compatible but doesn't enforce AWS regions
- `s3.bucket`: Must match the bucket name created in MinIO
- `s3.disableSslVerify`: Set to `true` when using self-signed certificates or for testing

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

**Enable LFS for specific project and all projects using MinIO S3 backend:**

```
[lfs "project-name"]
    enabled = true
    maxObjectSize = 1g
    backend = minio
[lfs "^.*$"]
    enabled = true
    maxObjectSize = 1g
    backend = minio
```

**Configuration Options:**
- `[lfs "project-name"]`: Specific project entry for top-level projects (projects without namespaces)
- `[lfs "^.*$"]`: Regex pattern to enable LFS for all projects (including top-level and namespaced)
- `enabled = true`: Enable LFS for matching projects
- `maxObjectSize = 1g`: Maximum object size (supports k, m, g suffixes)
- `backend = minio`: Use the MinIO S3 backend defined in global config. If not specified, defaults to filesystem backend (`fs`)

**Note:** The `backend = minio` setting ensures LFS objects are stored in your MinIO S3 bucket instead of the local filesystem. The backend name (`minio`) must match the section name in your global `lfs.config` file (e.g., `[s3 "minio"]`).

**Pattern Matching Priority:**
- If a project name matches several LFS namespaces, the one defined first in the config will be applied
- Specific project entries (e.g., `[lfs "project-name"]`) should be placed before pattern entries (e.g., `[lfs "^.*$"]`) for clarity

## Storage

This guide uses MinIO as an S3-compatible backend for Gerrit LFS. MinIO is a high-performance, S3-compatible object storage solution.

### Deploy MinIO

#### Using Docker Compose (Recommended)

Deploy MinIO using Docker Compose with the provided `docker-compose.yml`:

```bash
# Start MinIO
docker-compose up -d

# View logs
docker-compose logs -f

# Stop MinIO
docker-compose down
```

The `docker-compose.yml` file uses:
- Image: `craftslab/minio:latest`
- Bind mount: `./data:/data` (or customize to `/path/to/minio/data:/data`)
- Certificate mount: `./certs:/root/.minio/certs` (for HTTPS support)
- Ports: `9000` (S3 API) and `9001` (Console)
- Default credentials: `minioadmin` / `minioadmin`

**Important:** The certificate volume mount (`./certs:/root/.minio/certs`) is required for HTTPS support, which is necessary because the AWS S3 SDK (used by Gerrit LFS) defaults to HTTPS connections.

For the complete configuration, see [minio/docker-compose.yml](https://github.com/craftslab/minio/blob/master/docker-compose.yml).

#### Using Docker Run

Alternatively, run MinIO using the `craftslab/minio:latest` Docker image directly:

```bash
docker run -d \
  --name minio \
  -p 9000:9000 \
  -p 9001:9001 \
  -v /path/to/minio/data:/data \
  craftslab/minio:latest server /data --console-address :9001
```

**Credentials:**
- Access Key: `minioadmin`
- Secret Key: `minioadmin`

**Ports:**
- `9000`: S3 API endpoint (used by Gerrit LFS) - supports both HTTP and HTTPS
- `9001`: MinIO Console (web-based object browser)

### Generate SSL Certificates

**Required for HTTPS:** Since the AWS S3 SDK (used by Gerrit LFS) defaults to HTTPS, MinIO must be configured with SSL certificates.

#### For Testing (Self-Signed Certificates)

1. **Create certificates directory:**
   ```bash
   cd /path/to/minio
   mkdir -p certs
   ```

2. **Generate self-signed certificate:**
   ```bash
   cd certs
   openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
     -keyout private.key \
     -out public.pem \
     -subj "/C=US/ST=State/L=City/O=Organization/CN=YOUR_HOSTNAME_OR_IP"

   # Set proper permissions
   chmod 600 private.key
   chmod 644 public.pem
   ```

   **Replace `YOUR_HOSTNAME_OR_IP`** with your MinIO server's hostname or IP address.

3. **Verify certificate files:**
   ```bash
   ls -la certs/
   # Should show:
   # - private.key (private key file)
   # - public.pem (certificate file)
   ```

4. **Restart MinIO:**
   ```bash
   docker-compose down
   docker-compose up -d
   ```

5. **Verify HTTPS is working:**
   ```bash
   # Test HTTPS endpoint
   curl -k https://YOUR_HOSTNAME_OR_IP:9000/minio/health/live

   # Check MinIO logs
   docker-compose logs minio | grep -i "certificate\|https\|ssl"
   ```

**For Production:** Use proper SSL certificates from a Certificate Authority (CA) instead of self-signed certificates.

**Note:** MinIO automatically detects and uses certificates placed in `/root/.minio/certs` directory:
- `public.pem` (or `public.crt`) for the certificate
- `private.key` for the private key

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

## Usage

```bash
# Clone repo
git clone http://127.0.0.1:8080/a/test-repo
cd test-repo

# Configure LFS
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

## Troubleshooting

### Check LFS Logs

If you encounter issues with LFS operations, check the Git LFS logs:

```bash
# View the last LFS operation log
git lfs logs last

# View all LFS logs
git lfs logs

# View specific log file
cat .git/lfs/logs/YYYYMMDDTHHMMSS.XXXXXXXX.log
```

### Common Issues

1. **"LFS is not available for repository"**
   - Ensure the project is configured in `All-Projects/refs/meta/config/lfs.config`
   - For top-level projects, use specific project name (e.g., `[lfs "project-name"]`)
   - For all projects, use regex pattern `[lfs "^.*$"]`

2. **SSL/HTTPS Connection Errors**
   - Ensure MinIO is configured with SSL certificates (see [Generate SSL Certificates](#generate-ssl-certificates))
   - Verify `disableSslVerify = true` in `lfs.config` when using self-signed certificates
   - Check that hostname in `lfs.config` does NOT include `http://` or `https://` prefix

3. **Empty MinIO Bucket**
   - Verify files are tracked by Git LFS: `git lfs ls-files`
   - Check that `.gitattributes` exists and tracks the file types you're using
   - Ensure LFS files are actually being pushed (not just regular git files)

4. **Connection Refused or Unknown Host**
   - Verify MinIO is running: `docker-compose ps`
   - Test connectivity: `curl -k https://YOUR_HOSTNAME:9000/minio/health/live`
   - Check firewall rules and network connectivity between Gerrit and MinIO servers

## Reference

- [dev-buck](https://gerrit-documentation.storage.googleapis.com/Documentation/2.13/dev-buck.html)
- [gerrit-ci-plugin-lfs](https://gerrit-ci.gerritforge.com/job/plugin-lfs-bazel-master/lastSuccessfulBuild/console)
- [gerrit-plugins](https://www.gerritcodereview.com/plugins.html)
- [git-lfs](https://git-lfs.com)
- [lfs-build](https://gerrit.googlesource.com/plugins/lfs/+/refs/heads/stable-2.13/src/main/resources/Documentation/build.md)
- [lfs-config](https://gerrit.googlesource.com/plugins/lfs/+/refs/heads/master/src/main/resources/Documentation/config.md)
- [minio-s3](https://github.com/craftslab/minio)
