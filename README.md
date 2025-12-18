# gerritlfs

[English](./README.md) | [简体中文](./README_cn.md)

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
docker cp temp-container:/workspace/gerrit/plugins/lfs/lfs.jar ./lfs.jar

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

**For MinIO (S3-compatible) - Direct Access**

```
[s3 "minio"]
    hostname = localhost:9000
    region = us-east-1
    bucket = gerritlfs
    storageClass = REDUCED_REDUNDANCY
    expirationSeconds = 60
    disableSslVerify = true
```

**For MinIO (S3-compatible) - Behind Nginx Reverse Proxy**

When MinIO is behind an nginx reverse proxy serving at root path (recommended for production):

```
[s3 "minio"]
    hostname = your-domain.com
    region = us-east-1
    bucket = gerritlfs
    storageClass = REDUCED_REDUNDANCY
    expirationSeconds = 60
    disableSslVerify = true
```

**Important:** When using nginx reverse proxy:
- Configure nginx to serve MinIO S3 API at root path (`/`) for standard S3 endpoint compatibility
- Use only the domain name in `hostname` (e.g., `your-domain.com`), without protocol or path
- Do NOT include `http://`, `https://`, or path prefixes in the hostname
- The nginx reverse proxy should handle SSL termination and forward requests to MinIO

**For RustFS (S3-compatible) - Direct Access**

```
[s3 "rustfs"]
    hostname = localhost:9002
    region = us-east-1
    bucket = gerritlfs
    storageClass = REDUCED_REDUNDANCY
    expirationSeconds = 60
    disableSslVerify = true
```

**For RustFS (S3-compatible) - Behind Nginx Reverse Proxy**

When RustFS is behind an nginx reverse proxy serving at root path (recommended for production):

```
[s3 "rustfs"]
    hostname = your-domain.com
    region = us-east-1
    bucket = gerritlfs
    storageClass = REDUCED_REDUNDANCY
    expirationSeconds = 60
    disableSslVerify = true
```

**Important:** When using nginx reverse proxy:
- Configure nginx to serve RustFS S3 API at root path (`/`) for standard S3 endpoint compatibility
- Use only the domain name in `hostname` (e.g., `your-domain.com`), without protocol or path
- Do NOT include `http://`, `https://`, or path prefixes in the hostname
- The nginx reverse proxy should handle SSL termination and forward requests to RustFS

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
[s3 "minio"]
    accessKey = YOUR_ACCESS_KEY
    secretKey = YOUR_SECRET_KEY
```

Or for RustFS:

```
[s3 "rustfs"]
    accessKey = YOUR_ACCESS_KEY
    secretKey = YOUR_SECRET_KEY
```

**MinIO Configuration Options**
- `s3.hostname`: Use `hostname:port`, `ip:port`, or `domain.com` format
  - **Important:** Do NOT include `http://` or `https://` protocol prefix
  - **Important:** Do NOT include path prefixes (e.g., `/minio/api`) in hostname
  - For direct access: Use `localhost:9000` or `minio-server:9000`
  - For nginx reverse proxy: Use only the domain name (e.g., `your-domain.com`) - nginx should serve MinIO at root path
  - The AWS S3 SDK defaults to HTTPS, so ensure MinIO or nginx is configured with HTTPS (see [Generate SSL Certificates](#generate-ssl-certificates))
- `s3.region`: Can be any value (e.g., `us-east-1`) as MinIO is S3-compatible but doesn't enforce AWS regions
- `s3.bucket`: Must match the bucket name created in MinIO
- `s3.disableSslVerify`: Set to `true` when using self-signed certificates or for testing

**S3 Configuration Options**
- `s3.hostname`: Custom hostname for S3 API server
  - For MinIO (direct): Use `localhost:9000` (or your MinIO server hostname:port)
  - For MinIO (nginx proxy): Use domain name only (e.g., `your-domain.com`) - nginx must serve MinIO at root path
  - For RustFS (direct): Use `localhost:9002` (or your RustFS server hostname:port, or IP address for remote deployments)
  - For RustFS (nginx proxy): Use domain name only (e.g., `your-domain.com`) - nginx must serve RustFS at root path
  - For AWS: Use `s3.amazonaws.com` (default)
- `s3.region`: Amazon region where the S3 bucket resides (for MinIO/RustFS, any value is acceptable)
- `s3.bucket`: Name of the S3 storage bucket (must exist in MinIO/RustFS/AWS)
- `s3.storageClass`: S3 storage class (default: `REDUCED_REDUNDANCY`)
- `s3.expirationSeconds`: Validity of signed requests in seconds (default: `60`)
- `s3.disableSslVerify`: Disable SSL verification (default: `false`, set to `true` for local MinIO/RustFS without SSL)
- `s3.accessKey`: Access key (MinIO/RustFS access key or Amazon IAM access key, recommended in secure config)
- `s3.secretKey`: Secret key (MinIO/RustFS secret key or Amazon IAM secret key, recommended in secure config)

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

**Enable LFS for specific project and all projects using RustFS S3 backend:**

```
[lfs "project-name"]
    enabled = true
    maxObjectSize = 1g
    backend = rustfs
[lfs "^.*$"]
    enabled = true
    maxObjectSize = 1g
    backend = rustfs
```

**Configuration Options:**
- `[lfs "project-name"]`: Specific project entry for top-level projects (projects without namespaces)
- `[lfs "^.*$"]`: Regex pattern to enable LFS for all projects (including top-level and namespaced)
- `enabled = true`: Enable LFS for matching projects
- `maxObjectSize = 1g`: Maximum object size (supports k, m, g suffixes)
- `backend = minio` or `backend = rustfs`: Use the S3 backend defined in global config. If not specified, defaults to filesystem backend (`fs`)

**Note:** The `backend = minio` or `backend = rustfs` setting ensures LFS objects are stored in your S3 bucket instead of the local filesystem. The backend name (`minio` or `rustfs`) must match the section name in your global `lfs.config` file (e.g., `[s3 "minio"]` or `[s3 "rustfs"]`).

**Pattern Matching Priority:**
- If a project name matches several LFS namespaces, the one defined first in the config will be applied
- Specific project entries (e.g., `[lfs "project-name"]`) should be placed before pattern entries (e.g., `[lfs "^.*$"]`) for clarity

## Storage

This guide supports both MinIO and RustFS as S3-compatible backends for Gerrit LFS. Both are high-performance, S3-compatible object storage solutions.

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

#### Using Nginx Reverse Proxy (Recommended for Production)

For production deployments, it's recommended to use nginx as a reverse proxy in front of MinIO to handle SSL termination and provide a clean endpoint. The nginx configuration should serve MinIO S3 API at the root path (`/`) for standard S3 endpoint compatibility.

**Example nginx configuration:**

```nginx
server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name your-domain.com;

    ssl_certificate /etc/nginx/certs/public.crt;
    ssl_certificate_key /etc/nginx/certs/private.key;

    # To allow special characters in headers
    ignore_invalid_headers off;
    # Allow any size file to be uploaded
    client_max_body_size 0;
    # To disable buffering
    proxy_buffering off;
    proxy_request_buffering off;

    # MinIO S3 API endpoint at root
    location / {
        proxy_pass http://minio:9000/;

        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port 443;

        proxy_connect_timeout 300;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        chunked_transfer_encoding off;
    }
}
```

**Important:**
- MinIO S3 API must be served at root path (`/`) for compatibility with Gerrit LFS plugin
- The `hostname` in `lfs.config` should be set to your domain name only (e.g., `your-domain.com`)
- Do NOT include path prefixes in the hostname configuration
- Nginx handles SSL termination, so MinIO can run without SSL certificates when behind nginx

For the complete nginx and docker-compose configuration, see [minio/nginx.conf](https://github.com/craftslab/minio/blob/master/nginx.conf) and [minio/docker-compose.yml](https://github.com/craftslab/minio/blob/master/docker-compose.yml).

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

   **For IP address:**
   ```bash
   cd certs
   # Create certificate with IP address in Subject Alternative Name (SAN)
   openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
     -keyout private.key \
     -out public.crt \
     -subj "/C=US/ST=State/L=City/O=Organization/CN=YOUR_IP" \
     -addext "subjectAltName=IP:YOUR_IP"

   # Set proper permissions
   chmod 600 private.key
   chmod 644 public.crt
   ```

   **For hostname:**
   ```bash
   cd certs
   # Create certificate with hostname in Subject Alternative Name (SAN)
   openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
     -keyout private.key \
     -out public.crt \
     -subj "/C=US/ST=State/L=City/O=Organization/CN=YOUR_HOSTNAME" \
     -addext "subjectAltName=DNS:YOUR_HOSTNAME"

   # Set proper permissions
   chmod 600 private.key
   chmod 644 public.crt
   ```

   **For both IP and hostname:**
   ```bash
   cd certs
   openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
     -keyout private.key \
     -out public.crt \
     -subj "/C=US/ST=State/L=City/O=Organization/CN=YOUR_HOSTNAME" \
     -addext "subjectAltName=IP:YOUR_IP,DNS:YOUR_HOSTNAME"

   # Set proper permissions
   chmod 600 private.key
   chmod 644 public.crt
   ```

3. **Verify certificate files:**
   ```bash
   ls -la certs/
   # Should show:
   # - private.key (private key file)
   # - public.crt (certificate file)
   ```

4. **Restart MinIO:**
   ```bash
   docker-compose down
   docker-compose up -d
   ```

5. **Verify HTTPS is working:**
   ```bash
   # Test HTTPS endpoint
   curl -k https://YOUR_HOSTNAME_OR_IP:9000/minio/health

   # Check MinIO logs
   docker-compose logs minio | grep -i "certificate\|https\|ssl"
   ```

**For Production:** Use proper SSL certificates from a Certificate Authority (CA) instead of self-signed certificates.

**Note:** MinIO automatically detects and uses certificates placed in `/root/.minio/certs` directory:
- `public.crt` for the certificate
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

#### Install MinIO Client

```bash
# Download MinIO Client
curl https://dl.min.io/client/mc/release/linux-amd64/mc -o mc
chmod +x mc

# Or install via package manager
# Ubuntu/Debian: wget https://dl.min.io/client/mc/release/linux-amd64/mc -O /usr/local/bin/mc && chmod +x /usr/local/bin/mc
```

#### Configure MinIO Alias

```bash
# Set alias for your MinIO server (use HTTPS if certificates are configured)
mc alias set myminio https://minio_ip:9000 minioadmin minioadmin
```

#### Check Bucket Status

```bash
# List all buckets
mc ls myminio

# List objects in a specific bucket (e.g., gerritlfs)
mc ls myminio/gerritlfs

# Get detailed bucket information
mc stat myminio/gerritlfs

# Count objects in bucket
mc ls --recursive myminio/gerritlfs | wc -l

# Get bucket size and object count
mc du myminio/gerritlfs

# List objects with details (size, date)
mc ls --recursive myminio/gerritlfs

# Check if bucket exists
mc ls myminio/gerritlfs 2>&1 | grep -q "gerritlfs" && echo "Bucket exists" || echo "Bucket not found"
```

#### Other Useful Commands

```bash
# Get MinIO server information
mc admin info myminio

# Create a new bucket
mc mb myminio/my-new-bucket

# Remove a bucket (be careful!)
# mc rb myminio/my-bucket

# Copy files to/from bucket
# mc cp local-file.txt myminio/gerritlfs/
# mc cp myminio/gerritlfs/file.txt ./
```

For more information, refer to the [MinIO Quickstart Guide](https://github.com/craftslab/minio).

### Deploy RustFS

RustFS is a lightweight, S3-compatible object storage solution written in Rust. It provides high performance and low resource usage.

#### Using Docker Run

```bash
mkdir -p ./data ./logs
chmod -R 777 ./data ./logs

docker run -d \
  --name rustfs_container \
  --user root \
  -p 9002:9000 \
  -p 9003:9001 \
  -v /path/to/rustfs/data:/data \
  -v /path/to/rustfs/logs:/logs \
  -e RUSTFS_ACCESS_KEY=rustfsadmin \
  -e RUSTFS_SECRET_KEY=rustfsadmin \
  -e RUSTFS_CONSOLE_ENABLE=true \
  rustfs/rustfs:latest \
  --address :9000 \
  --console-enable \
  --access-key rustfsadmin \
  --secret-key rustfsadmin \
  /data
```

**Credentials:**
- Access Key: `rustfsadmin` (default, change for production)
- Secret Key: `rustfsadmin` (default, change for production)

**Ports:**
- `9002`: S3 API endpoint (used by Gerrit LFS) - mapped from container port 9000
- `9003`: RustFS Console (web-based object browser) - mapped from container port 9001

**Important:**
- **AWS S3 SDK (used by Gerrit LFS plugin) defaults to HTTPS connections**
- RustFS must be configured with HTTPS/SSL certificates OR use nginx reverse proxy with HTTPS
- If RustFS runs on HTTP only, Gerrit LFS plugin will fail with "unexpected EOF" or connection errors
- For production, configure RustFS with SSL certificates (see [Generate SSL Certificates for RustFS](#generate-ssl-certificates-for-rustfs)) or use nginx reverse proxy

#### Using Nginx Reverse Proxy (Recommended for Production)

For production deployments, use nginx as a reverse proxy in front of RustFS to handle SSL termination. The nginx configuration should serve RustFS S3 API at the root path (`/`) and expose the RustFS console paths.

```nginx
server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name your-domain.com;

    ssl_certificate /etc/nginx/certs/public.crt;
    ssl_certificate_key /etc/nginx/certs/private.key;

    # To allow special characters in headers
    ignore_invalid_headers off;
    # Allow any size file to be uploaded
    client_max_body_size 0;
    # To disable buffering
    proxy_buffering off;
    proxy_request_buffering off;

    # RustFS Web Console at /rustfs/console/
    location /rustfs/console/ {
        proxy_pass http://rustfs:9001/rustfs/console/;

        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port 443;

        proxy_connect_timeout 300;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        chunked_transfer_encoding off;
    }

    # RustFS Web Console at /ui (alternative path)
    location /ui/ {
        proxy_pass http://rustfs:9001/;

        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port 443;

        proxy_connect_timeout 300;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        chunked_transfer_encoding off;
    }

    location = /ui {
        return 301 /ui/;
    }

    # RustFS S3 API endpoint at root
    location / {
        proxy_pass http://rustfs:9000/;

        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port 443;

        proxy_connect_timeout 300;
        # Default is HTTP/1, keepalive is only enabled in HTTP/1.1
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        chunked_transfer_encoding off;
    }
}
```

**Important:**
- RustFS S3 API must be served at root path (`/`) for compatibility with Gerrit LFS plugin, while the console remains available at `/rustfs/console/` or `/ui`
- The `hostname` in `lfs.config` should be set to your domain name only (e.g., `your-domain.com`)
- Do NOT include path prefixes in the hostname configuration
- Nginx handles SSL termination, so RustFS can run without SSL certificates when behind nginx

### Generate SSL Certificates for RustFS

**Required for HTTPS:** Since the AWS S3 SDK (used by Gerrit LFS) defaults to HTTPS, RustFS **MUST** be configured with SSL certificates when accessed directly (not behind nginx). Without HTTPS, Gerrit LFS plugin will fail with "unexpected EOF" or connection errors.

**Note:** If you cannot configure HTTPS on RustFS, use nginx reverse proxy with HTTPS as an alternative solution.

The SSL certificate generation process is similar to MinIO. Refer to the [Generate SSL Certificates](#generate-ssl-certificates) section above for detailed instructions.

### Create Credentials for RustFS

1. **Access RustFS Console:**
    - Open your browser to `http://localhost:9003`
    - Login with default credentials: `rustfsadmin` / `rustfsadmin`

2. **Create a Bucket:**
    - Navigate to Buckets section
    - Create a new bucket (e.g., `gerritlfs`)

3. **Create Access Key (Recommended for Production):**
    - Navigate to Access Keys section
    - Create a new access key with appropriate permissions
    - Save the Access Key and Secret Key for use in Gerrit configuration

### Test Connectivity for RustFS

You can test RustFS using the MinIO Client (`mc`) or AWS CLI, as RustFS is S3-compatible:

#### Install MinIO Client

```bash
# Download MinIO Client
curl https://dl.min.io/client/mc/release/linux-amd64/mc -o mc
chmod +x mc
```

#### Configure RustFS Alias

```bash
# Set alias for your RustFS server (use HTTPS if certificates are configured)
mc alias set myrustfs http://localhost:9002 rustfsadmin rustfsadmin
```

#### Check Bucket Status

```bash
# List all buckets
mc ls myrustfs

# List objects in a specific bucket (e.g., gerritlfs)
mc ls myrustfs/gerritlfs

# Get detailed bucket information
mc stat myrustfs/gerritlfs

# Count objects in bucket
mc ls --recursive myrustfs/gerritlfs | wc -l

# Get bucket size and object count
mc du myrustfs/gerritlfs
```

For more information, refer to the [RustFS Documentation](https://docs.rustfs.com/).

## Usage

```bash
# Clone repo
git clone http://127.0.0.1:8080/a/test-repo
cd test-repo

# Configure LFS
git config lfs.url http://127.0.0.1:8080/a/test-repo/info/lfs
git config credential.helper store

# For self-signed certificates, add certificate to system trust store (RECOMMENDED)
# This is REQUIRED because git-lfs uploads directly to RustFS using pre-signed URLs
# and doesn't trust self-signed certificates by default
#
# Step 1: Copy certificate from RustFS server to local machine
scp user@rustfs-server:/path/to/rustfs/certs/public.crt /tmp/rustfs.crt

# Step 2: Add certificate to system trust store
sudo cp /tmp/rustfs.crt /usr/local/share/ca-certificates/rustfs.crt
sudo update-ca-certificates

# Step 3: Verify certificate was added
ls -la /etc/ssl/certs/ | grep rustfs

# Verify LFS is configured
git ls-remote http://127.0.0.1:8080/a/test-repo

# Trace file types that will be stored on S3 backend (MinIO, RustFS, or AWS S3)
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
# The file should be accessible on S3 server
# - For MinIO: check MinIO Console at http://localhost:9001
# - For RustFS: check RustFS Console at http://localhost:9003
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
   - Ensure MinIO or RustFS is configured with SSL certificates (see [Generate SSL Certificates](#generate-ssl-certificates))
   - **"certificate signed by unknown authority" error (git-lfs):**
     - This occurs when git-lfs doesn't trust the self-signed certificate
     - **Solution (Recommended):** Add the certificate to your system's trust store:
       ```bash
       # Step 1: Copy certificate from S3 server to local machine
       # For MinIO:
       scp user@minio-server:/path/to/minio/certs/public.crt /tmp/minio.crt
       # For RustFS:
       scp user@rustfs-server:/path/to/rustfs/certs/public.crt /tmp/rustfs.crt

       # Step 2: Add certificate to system trust store
       sudo cp /tmp/minio.crt /usr/local/share/ca-certificates/minio.crt
       # OR for RustFS:
       sudo cp /tmp/rustfs.crt /usr/local/share/ca-certificates/rustfs.crt
       sudo update-ca-certificates

       # Step 3: Verify certificate was added
       ls -la /etc/ssl/certs/ | grep minio
       # OR for RustFS:
       ls -la /etc/ssl/certs/ | grep rustfs
       ```
       After this, git-lfs will trust the certificate and you can push without errors.
     - **Alternative (Testing only):** Environment variable or git config (may not work with all git-lfs versions):
       ```bash
       export GIT_LFS_SKIP_SSL_VERIFY=1
       # OR
       git config lfs.https://minio_ip:9000/.sslverify false
       # OR for RustFS:
       git config lfs.https://rustfs_ip:9002/.sslverify false
       ```
       **Note:** These methods may not work reliably with git-lfs 3.4+. Adding to trust store is the recommended solution.
   - Verify `disableSslVerify = true` in `lfs.config` when using self-signed certificates (this only affects Gerrit's connection, not git-lfs)
   - Check that hostname in `lfs.config` does NOT include `http://` or `https://` prefix

3. **Empty S3 Bucket (MinIO or RustFS)**
   - Verify files are tracked by Git LFS: `git lfs ls-files`
   - Check that `.gitattributes` exists and tracks the file types you're using
   - Ensure LFS files are actually being pushed (not just regular git files)

4. **Connection Refused or Unknown Host**
   - Verify S3 server is running:
     - For MinIO: `docker-compose ps` or `docker ps | grep minio`
     - For RustFS: `docker ps | grep rustfs`
   - Test connectivity:
     - MinIO direct access: `curl -k https://YOUR_HOSTNAME:9000/minio/health`
     - RustFS direct access: `curl -k https://YOUR_HOSTNAME:9002/health`
     - Via nginx: `curl -k https://YOUR_DOMAIN/health`
   - Check firewall rules and network connectivity between Gerrit and S3 servers
   - If using nginx reverse proxy, verify nginx is running and properly configured

5. **"UnknownHostException: https: Name or service not known" Error**
   - This error occurs when the hostname includes a protocol prefix (`http://` or `https://`)
   - **Solution:** Remove protocol prefix from `hostname` in `lfs.config`
     - ❌ Wrong: `hostname = https://your-domain.com`
     - ✅ Correct: `hostname = your-domain.com`
   - If using nginx reverse proxy, ensure hostname is domain name only (no path prefixes)
     - ❌ Wrong: `hostname = your-domain.com/minio/api` or `hostname = your-domain.com/rustfs/api`
     - ✅ Correct: `hostname = your-domain.com`
     - Configure nginx to serve S3 API at root path (`/`) instead of a subpath

6. **Adding lfs.config to All-Projects.git Bare Repository (Gerrit 2.13)**
   - **Problem:** When you cannot push `lfs.config` via HTTP due to permission issues (e.g., "You are not allowed to perform this operation"), you need to add it directly to the bare repository on the server.
   - **Solution:** Use the `transfer-commit.sh` script provided in the `2.13/` directory.
   - **Steps:**
     1. **Prepare your lfs.config file:**
        ```bash
        # Create or edit your lfs.config file
        cd ~/my-tmp/google-gerrit/All-Projects-2.13.4
        # Edit lfs.config with your configuration
        nano lfs.config
        ```
     2. **Create a temporary working repository:**
        ```bash
        cd /tmp
        mkdir fix-gerrit && cd fix-gerrit
        git clone ~/my-tmp/google-gerrit/install-2.13.4/git/All-Projects.git temp-repo
        cd temp-repo
        ```
     3. **Checkout refs/meta/config and add lfs.config:**
        ```bash
        git fetch origin refs/meta/config:refs/meta/config
        git checkout refs/meta/config
        cp ~/my-tmp/google-gerrit/All-Projects-2.13.4/lfs.config .
        git add lfs.config
        git commit -m "Add lfs.config for Git LFS configuration"
        NEW_COMMIT=$(git rev-parse HEAD)
        ```
     4. **Use transfer-commit.sh to transfer the commit to bare repository:**
        ```bash
        # Copy the script to your working directory
        cp ~/my-tmp/gerritlfs/2.13/transfer-commit.sh .

        # Edit the script to set correct paths:
        # - TEMP_REPO: path to your temp-repo (e.g., /tmp/fix-gerrit/temp-repo)
        # - BARE_REPO: path to All-Projects.git bare repository
        # - NEW_COMMIT: the commit hash from step 3

        # Run the script
        bash transfer-commit.sh
        ```
     - **What the script does:**
       - Tries to push the commit directly from temp-repo to bare repository (most reliable)
       - Falls back to fetching objects if push fails
       - Falls back to copying Git objects directly if fetch fails
       - Updates `refs/meta/config` in the bare repository
       - Verifies that `lfs.config` exists and shows its contents
   - **Alternative Quick Method:**
     ```bash
     # From temp-repo, push directly to bare repository
     cd /tmp/fix-gerrit/temp-repo
     git push ~/my-tmp/google-gerrit/install-2.13.4/git/All-Projects.git refs/meta/config:refs/meta/config

     # Verify
     cd ~/my-tmp/google-gerrit/install-2.13.4/git/All-Projects.git
     git show refs/meta/config:lfs.config
     ```
   - **After adding lfs.config:**
     - Restart Gerrit to load the new configuration: `systemctl restart gerrit`
     - The configuration will be inherited by all projects
     - Test LFS functionality by pushing a large file to a project

## Reference

- [dev-buck](https://gerrit-documentation.storage.googleapis.com/Documentation/2.13/dev-buck.html)
- [gerrit-ci-plugin-lfs](https://gerrit-ci.gerritforge.com/job/plugin-lfs-bazel-master/lastSuccessfulBuild/console)
- [gerrit-plugins](https://www.gerritcodereview.com/plugins.html)
- [git-lfs](https://git-lfs.com)
- [lfs-build](https://gerrit.googlesource.com/plugins/lfs/+/refs/heads/stable-2.13/src/main/resources/Documentation/build.md)
- [lfs-config](https://gerrit.googlesource.com/plugins/lfs/+/refs/heads/master/src/main/resources/Documentation/config.md)
- [minio-s3](https://github.com/craftslab/minio)
- [rustfs-s3](https://github.com/craftslab/rustfs)
