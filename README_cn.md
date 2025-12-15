# gerritlfs

[English](./README.md) | [简体中文](./README_cn.md)

## 概述

- [2.13](https://github.com/craftslab/gerritlfs/tree/main/2.13) - Gerrit 2.13 版本构建文件
- [3.2](https://github.com/craftslab/gerritlfs/tree/main/3.2) - Gerrit 3.2 版本构建文件

## 前置要求

### 安装 Git LFS

在使用此插件之前必须安装 Git LFS。如果遇到以下错误：
```
fatal: 'lfs' appears to be a git command, but we were not able to execute it. Maybe git-lfs is broken?
```

使用以下方法之一在 Ubuntu 上安装 Git LFS：

**方法 1：使用 apt（推荐用于 Ubuntu 24.04）**

```bash
# 更新软件包列表
sudo apt update

# 安装 git-lfs
sudo apt install git-lfs

# 初始化 Git LFS
git lfs install
```

**方法 2：使用官方 Git LFS 仓库**

```bash
# 添加 Git LFS 仓库
curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash

# 安装 git-lfs
sudo apt install git-lfs

# 初始化 Git LFS
git lfs install
```

安装后，验证是否正常工作：

```bash
git lfs version
```

您应该看到类似 `git-lfs/3.x.x` 的输出。

**注意：** `git lfs install` 命令会在您的 Git 配置中设置 Git LFS 钩子。每个用户账户只需运行一次。

## 安装

### 构建 LFS 插件

LFS 插件必须构建并安装在您的 Gerrit 服务器上才能使用。根据您的 Gerrit 版本选择构建方法：

#### 对于 Gerrit 3.2

1. **使用 Docker 构建插件：**

```bash
cd 3.2
./build.sh
```

这将创建一个包含已构建插件的 Docker 镜像 `gerrit-plugins-lfs:3.2`。

2. **从 Docker 容器中提取 lfs.jar：**

```bash
# 从镜像创建临时容器
docker create --name temp-container gerrit-plugins-lfs:3.2

# 从容器复制 lfs.jar
docker cp temp-container:/workspace/output/lfs.jar ./lfs.jar

# 删除临时容器
docker rm temp-container
```

#### 对于 Gerrit 2.13

1. **使用 Docker 构建插件：**

```bash
cd 2.13
./build.sh
```

这将创建一个包含已构建插件的 Docker 镜像 `gerrit-plugins-lfs:2.13`。

2. **从 Docker 容器中提取 lfs.jar：**

```bash
# 从镜像创建临时容器
docker create --name temp-container gerrit-plugins-lfs:2.13

# 从容器复制 lfs.jar
# 注意：对于 2.13，JAR 位置可能不同。检查容器：
docker cp temp-container:/workspace/gerrit/plugins/lfs/lfs.jar ./lfs.jar

# 或者如果使用 Buck 构建：
docker cp temp-container:/workspace/gerrit/buck-out/gen/plugins/lfs/lfs.jar ./lfs.jar

# 删除临时容器
docker rm temp-container
```

### 在 Gerrit 服务器上安装插件

1. **将 lfs.jar 复制到 Gerrit 插件目录：**

```bash
# 将构建的 lfs.jar 复制到您的 Gerrit 安装目录
cp lfs.jar /path/to/gerrit/plugins/lfs.jar

# 确保正确的权限
chown gerrit:gerrit /path/to/gerrit/plugins/lfs.jar
chmod 644 /path/to/gerrit/plugins/lfs.jar
```

2. **重启 Gerrit：**

```bash
# 重启您的 Gerrit 服务器以加载插件
# 具体命令取决于您的 Gerrit 安装方法
systemctl restart gerrit
# 或者
/path/to/gerrit/bin/gerrit.sh restart
```

3. **验证插件已加载：**

检查 Gerrit 日志或 Web 界面以确认 LFS 插件已加载。您应该在 Gerrit 插件页面或启动日志中看到该插件。

**注意：** 插件必须在配置之前安装。安装后，请继续到 [配置](#config) 部分配置插件。

## 配置

### 1. /path/to/gerrit/etc/gerrit.config

```
[plugin "lfs"]
    enabled = true
[lfs]
    plugin = lfs
```

### 2. /path/to/gerrit/etc/lfs.config

**对于 MinIO（S3 兼容）- 直接访问**

```
[s3 "minio"]
    hostname = localhost:9000
    region = us-east-1
    bucket = gerritlfs
    storageClass = REDUCED_REDUNDANCY
    expirationSeconds = 60
    disableSslVerify = true
```

**对于 MinIO（S3 兼容）- 在 Nginx 反向代理后**

当 MinIO 位于在根路径提供服务的 nginx 反向代理后时（推荐用于生产环境）：

```
[s3 "minio"]
    hostname = your-domain.com
    region = us-east-1
    bucket = gerritlfs
    storageClass = REDUCED_REDUNDANCY
    expirationSeconds = 60
    disableSslVerify = true
```

**重要提示：** 使用 nginx 反向代理时：
- 配置 nginx 在根路径 (`/`) 提供 MinIO S3 API，以实现标准 S3 端点兼容性
- 在 `hostname` 中仅使用域名（例如，`your-domain.com`），不带协议或路径
- 不要在主机名中包含 `http://`、`https://` 或路径前缀
- nginx 反向代理应处理 SSL 终止并将请求转发到 MinIO

**对于 RustFS（S3 兼容）- 直接访问**

```
[s3 "rustfs"]
    hostname = localhost:9002
    region = us-east-1
    bucket = gerritlfs
    storageClass = REDUCED_REDUNDANCY
    expirationSeconds = 60
    disableSslVerify = true
```

**对于 RustFS（S3 兼容）- 在 Nginx 反向代理后**

当 RustFS 位于在根路径提供服务的 nginx 反向代理后时（推荐用于生产环境）：

```
[s3 "rustfs"]
    hostname = your-domain.com
    region = us-east-1
    bucket = gerritlfs
    storageClass = REDUCED_REDUNDANCY
    expirationSeconds = 60
    disableSslVerify = true
```

**重要提示：** 使用 nginx 反向代理时：
- 配置 nginx 在根路径 (`/`) 提供 RustFS S3 API，以实现标准 S3 端点兼容性
- 在 `hostname` 中仅使用域名（例如，`your-domain.com`），不带协议或路径
- 不要在主机名中包含 `http://`、`https://` 或路径前缀
- nginx 反向代理应处理 SSL 终止并将请求转发到 RustFS

**对于 AWS S3**

```
[s3 "aws"]
    hostname = s3.amazonaws.com
    region = us-east-1
    bucket = my-lfs-bucket
    storageClass = REDUCED_REDUNDANCY
    expirationSeconds = 60
    disableSslVerify = true
```

**注意：** 为了安全起见，请将 `s3.accessKey` 和 `s3.secretKey` 放在 `/path/to/gerrit/etc/lfs.secure.config` 中：

```
[s3 "minio"]
    accessKey = YOUR_ACCESS_KEY
    secretKey = YOUR_SECRET_KEY
```

或对于 RustFS：

```
[s3 "rustfs"]
    accessKey = YOUR_ACCESS_KEY
    secretKey = YOUR_SECRET_KEY
```

**MinIO 配置选项**
- `s3.hostname`：使用 `hostname:port`、`ip:port` 或 `domain.com` 格式
  - **重要：** 不要包含 `http://` 或 `https://` 协议前缀
  - **重要：** 不要在主机名中包含路径前缀（例如，`/minio/api`）
  - 对于直接访问：使用 `localhost:9000` 或 `minio-server:9000`
  - 对于 nginx 反向代理：仅使用域名（例如，`your-domain.com`）- nginx 应在根路径提供 MinIO
  - AWS S3 SDK 默认为 HTTPS，因此确保 MinIO 或 nginx 配置了 HTTPS（参见 [生成 SSL 证书](#generate-ssl-certificates)）
- `s3.region`：可以是任何值（例如，`us-east-1`），因为 MinIO 是 S3 兼容的但不强制 AWS 区域
- `s3.bucket`：必须与在 MinIO 中创建的存储桶名称匹配
- `s3.disableSslVerify`：使用自签名证书或测试时设置为 `true`

**S3 配置选项**
- `s3.hostname`：S3 API 服务器的自定义主机名
  - 对于 MinIO（直接）：使用 `localhost:9000`（或您的 MinIO 服务器主机名:端口）
  - 对于 MinIO（nginx 代理）：仅使用域名（例如，`your-domain.com`）- nginx 必须在根路径提供 MinIO
  - 对于 RustFS（直接）：使用 `localhost:9002`（或您的 RustFS 服务器主机名:端口，或用于远程部署的 IP 地址）
  - 对于 RustFS（nginx 代理）：仅使用域名（例如，`your-domain.com`）- nginx 必须在根路径提供 RustFS
  - 对于 AWS：使用 `s3.amazonaws.com`（默认）
- `s3.region`：S3 存储桶所在的 Amazon 区域（对于 MinIO/RustFS，任何值都可以接受）
- `s3.bucket`：S3 存储桶的名称（必须在 MinIO/RustFS/AWS 中存在）
- `s3.storageClass`：S3 存储类（默认：`REDUCED_REDUNDANCY`）
- `s3.expirationSeconds`：签名请求的有效期（秒）（默认：`60`）
- `s3.disableSslVerify`：禁用 SSL 验证（默认：`false`，对于没有 SSL 的本地 MinIO/RustFS 设置为 `true`）
- `s3.accessKey`：访问密钥（MinIO/RustFS 访问密钥或 Amazon IAM 访问密钥，建议放在安全配置中）
- `s3.secretKey`：密钥（MinIO/RustFS 密钥或 Amazon IAM 密钥，建议放在安全配置中）

### 3. All-Projects/refs/meta/config/lfs.config

**为特定项目和所有项目启用 LFS，使用 MinIO S3 后端：**

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

**为特定项目和所有项目启用 LFS，使用 RustFS S3 后端：**

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

**配置选项：**
- `[lfs "project-name"]`：顶级项目（没有命名空间的项目）的特定项目条目
- `[lfs "^.*$"]`：为所有项目（包括顶级和命名空间）启用 LFS 的正则表达式模式
- `enabled = true`：为匹配的项目启用 LFS
- `maxObjectSize = 1g`：最大对象大小（支持 k、m、g 后缀）
- `backend = minio` 或 `backend = rustfs`：使用全局配置中定义的 S3 后端。如果未指定，默认为文件系统后端 (`fs`)

**注意：** `backend = minio` 或 `backend = rustfs` 设置确保 LFS 对象存储在您的 S3 存储桶中，而不是本地文件系统。后端名称（`minio` 或 `rustfs`）必须与全局 `lfs.config` 文件中的节名称匹配（例如，`[s3 "minio"]` 或 `[s3 "rustfs"]`）。

**模式匹配优先级：**
- 如果项目名称匹配多个 LFS 命名空间，将应用配置中首先定义的那个
- 特定项目条目（例如，`[lfs "project-name"]`）应放在模式条目（例如，`[lfs "^.*$"]`）之前，以便清晰

## 存储

本指南支持 MinIO 和 RustFS 作为 Gerrit LFS 的 S3 兼容后端。两者都是高性能、S3 兼容的对象存储解决方案。

### 部署 MinIO

#### 使用 Docker Compose（推荐）

使用提供的 `docker-compose.yml` 部署 MinIO：

```bash
# 启动 MinIO
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止 MinIO
docker-compose down
```

`docker-compose.yml` 文件使用：
- 镜像：`craftslab/minio:latest`
- 绑定挂载：`./data:/data`（或自定义为 `/path/to/minio/data:/data`）
- 证书挂载：`./certs:/root/.minio/certs`（用于 HTTPS 支持）
- 端口：`9000`（S3 API）和 `9001`（控制台）
- 默认凭据：`minioadmin` / `minioadmin`

**重要提示：** 证书卷挂载（`./certs:/root/.minio/certs`）是 HTTPS 支持所必需的，这是必要的，因为 AWS S3 SDK（Gerrit LFS 使用）默认为 HTTPS 连接。

完整配置请参见 [minio/docker-compose.yml](https://github.com/craftslab/minio/blob/master/docker-compose.yml)。

#### 使用 Nginx 反向代理（推荐用于生产环境）

对于生产部署，建议使用 nginx 作为 MinIO 前面的反向代理来处理 SSL 终止并提供干净的端点。nginx 配置应在根路径 (`/`) 提供 MinIO S3 API，以实现标准 S3 端点兼容性。

**nginx 配置示例：**

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

    # 允许标头中的特殊字符
    ignore_invalid_headers off;
    # 允许上传任意大小的文件
    client_max_body_size 0;
    # 禁用缓冲
    proxy_buffering off;
    proxy_request_buffering off;

    # MinIO S3 API 端点在根路径
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

**重要提示：**
- MinIO S3 API 必须在根路径 (`/`) 提供服务，以兼容 Gerrit LFS 插件
- `lfs.config` 中的 `hostname` 应仅设置为您的域名（例如，`your-domain.com`）
- 不要在主机名配置中包含路径前缀
- Nginx 处理 SSL 终止，因此 MinIO 在 nginx 后运行时可以不需要 SSL 证书

完整的 nginx 和 docker-compose 配置，请参见 [minio/nginx.conf](https://github.com/craftslab/minio/blob/master/nginx.conf) 和 [minio/docker-compose.yml](https://github.com/craftslab/minio/blob/master/docker-compose.yml)。

#### 使用 Docker Run

或者，直接使用 `craftslab/minio:latest` Docker 镜像运行 MinIO：

```bash
docker run -d \
  --name minio \
  -p 9000:9000 \
  -p 9001:9001 \
  -v /path/to/minio/data:/data \
  craftslab/minio:latest server /data --console-address :9001
```

**凭据：**
- 访问密钥：`minioadmin`
- 密钥：`minioadmin`

**端口：**
- `9000`：S3 API 端点（Gerrit LFS 使用）- 支持 HTTP 和 HTTPS
- `9001`：MinIO 控制台（基于 Web 的对象浏览器）

### 生成 SSL 证书

**HTTPS 必需：** 由于 AWS S3 SDK（Gerrit LFS 使用）默认为 HTTPS，MinIO 必须配置 SSL 证书。

#### 用于测试（自签名证书）

1. **创建证书目录：**
   ```bash
   cd /path/to/minio
   mkdir -p certs
   ```

2. **生成自签名证书：**

   **对于 IP 地址：**
   ```bash
   cd certs
   # 创建在主题备用名称 (SAN) 中包含 IP 地址的证书
   openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
     -keyout private.key \
     -out public.crt \
     -subj "/C=US/ST=State/L=City/O=Organization/CN=YOUR_IP" \
     -addext "subjectAltName=IP:YOUR_IP"

   # 设置适当的权限
   chmod 600 private.key
   chmod 644 public.crt
   ```

   **对于主机名：**
   ```bash
   cd certs
   # 创建在主题备用名称 (SAN) 中包含主机名的证书
   openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
     -keyout private.key \
     -out public.crt \
     -subj "/C=US/ST=State/L=City/O=Organization/CN=YOUR_HOSTNAME" \
     -addext "subjectAltName=DNS:YOUR_HOSTNAME"

   # 设置适当的权限
   chmod 600 private.key
   chmod 644 public.crt
   ```

   **对于 IP 和主机名：**
   ```bash
   cd certs
   openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
     -keyout private.key \
     -out public.crt \
     -subj "/C=US/ST=State/L=City/O=Organization/CN=YOUR_HOSTNAME" \
     -addext "subjectAltName=IP:YOUR_IP,DNS:YOUR_HOSTNAME"

   # 设置适当的权限
   chmod 600 private.key
   chmod 644 public.crt
   ```

3. **验证证书文件：**
   ```bash
   ls -la certs/
   # 应该显示：
   # - private.key（私钥文件）
   # - public.crt（证书文件）
   ```

4. **重启 MinIO：**
   ```bash
   docker-compose down
   docker-compose up -d
   ```

5. **验证 HTTPS 是否正常工作：**
   ```bash
   # 测试 HTTPS 端点
   curl -k https://YOUR_HOSTNAME_OR_IP:9000/minio/health/live

   # 检查 MinIO 日志
   docker-compose logs minio | grep -i "certificate\|https\|ssl"
   ```

**用于生产环境：** 使用来自证书颁发机构 (CA) 的适当 SSL 证书，而不是自签名证书。

**注意：** MinIO 会自动检测并使用放置在 `/root/.minio/certs` 目录中的证书：
- `public.crt` 用于证书
- `private.key` 用于私钥

### 创建凭据

1. **访问 MinIO 控制台：**
    - 在浏览器中打开 `http://localhost:9001`
    - 使用默认凭据登录：`minioadmin` / `minioadmin`

2. **创建存储桶：**
    - 导航到存储桶部分
    - 创建新存储桶（例如，`my-lfs-bucket`）

3. **创建访问密钥（推荐用于生产环境）：**
    - 导航到访问密钥部分
    - 创建具有适当权限的新访问密钥
    - 保存访问密钥和密钥以供 Gerrit 配置使用

### 测试连接

您可以使用 MinIO 客户端 (`mc`) 测试 MinIO：

#### 安装 MinIO 客户端

```bash
# 下载 MinIO 客户端
curl https://dl.min.io/client/mc/release/linux-amd64/mc -o mc
chmod +x mc

# 或通过包管理器安装
# Ubuntu/Debian: wget https://dl.min.io/client/mc/release/linux-amd64/mc -O /usr/local/bin/mc && chmod +x /usr/local/bin/mc
```

#### 配置 MinIO 别名

```bash
# 为您的 MinIO 服务器设置别名（如果配置了证书，使用 HTTPS）
mc alias set myminio https://minio_ip:9000 minioadmin minioadmin
```

#### 检查存储桶状态

```bash
# 列出所有存储桶
mc ls myminio

# 列出特定存储桶中的对象（例如，gerritlfs）
mc ls myminio/gerritlfs

# 获取详细的存储桶信息
mc stat myminio/gerritlfs

# 统计存储桶中的对象数
mc ls --recursive myminio/gerritlfs | wc -l

# 获取存储桶大小和对象数
mc du myminio/gerritlfs

# 列出对象的详细信息（大小、日期）
mc ls --recursive myminio/gerritlfs

# 检查存储桶是否存在
mc ls myminio/gerritlfs 2>&1 | grep -q "gerritlfs" && echo "Bucket exists" || echo "Bucket not found"
```

#### 其他有用的命令

```bash
# 获取 MinIO 服务器信息
mc admin info myminio

# 创建新存储桶
mc mb myminio/my-new-bucket

# 删除存储桶（小心！）
# mc rb myminio/my-bucket

# 在存储桶之间复制文件
# mc cp local-file.txt myminio/gerritlfs/
# mc cp myminio/gerritlfs/file.txt ./
```

更多信息，请参考 [MinIO 快速入门指南](https://github.com/craftslab/minio)。

### 部署 RustFS

RustFS 是一个用 Rust 编写的轻量级、S3 兼容的对象存储解决方案。它提供高性能和低资源使用。

#### 使用 Docker Run

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

**凭据：**
- 访问密钥：`rustfsadmin`（默认，生产环境请更改）
- 密钥：`rustfsadmin`（默认，生产环境请更改）

**端口：**
- `9002`：S3 API 端点（Gerrit LFS 使用）- 从容器端口 9000 映射
- `9003`：RustFS 控制台（基于 Web 的对象浏览器）- 从容器端口 9001 映射

**重要提示：**
- **AWS S3 SDK（Gerrit LFS 插件使用）默认为 HTTPS 连接**
- RustFS 必须配置 HTTPS/SSL 证书或使用带 HTTPS 的 nginx 反向代理
- 如果 RustFS 仅在 HTTP 上运行，Gerrit LFS 插件将失败，出现"unexpected EOF"或连接错误
- 对于生产环境，配置 RustFS 使用 SSL 证书（参见 [为 RustFS 生成 SSL 证书](#generate-ssl-certificates-for-rustfs)）或使用 nginx 反向代理

#### 使用 Nginx 反向代理（推荐用于生产环境）

对于生产部署，使用 nginx 作为 RustFS 前面的反向代理来处理 SSL 终止。nginx 配置应在根路径 (`/`) 提供 RustFS S3 API，并公开 RustFS 控制台路径。

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

    # 允许标头中的特殊字符
    ignore_invalid_headers off;
    # 允许上传任意大小的文件
    client_max_body_size 0;
    # 禁用缓冲
    proxy_buffering off;
    proxy_request_buffering off;

    # RustFS Web 控制台在 /rustfs/console/
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

    # RustFS Web 控制台在 /ui（备用路径）
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

    # RustFS S3 API 端点在根路径
    location / {
        proxy_pass http://rustfs:9000/;

        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port 443;

        proxy_connect_timeout 300;
        # 默认是 HTTP/1，keepalive 仅在 HTTP/1.1 中启用
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        chunked_transfer_encoding off;
    }
}
```

**重要提示：**
- RustFS S3 API 必须在根路径 (`/`) 提供服务，以兼容 Gerrit LFS 插件，而控制台在 `/rustfs/console/` 或 `/ui` 保持可用
- `lfs.config` 中的 `hostname` 应仅设置为您的域名（例如，`your-domain.com`）
- 不要在主机名配置中包含路径前缀
- Nginx 处理 SSL 终止，因此 RustFS 在 nginx 后运行时可以不需要 SSL 证书

### 为 RustFS 生成 SSL 证书

**HTTPS 必需：** 由于 AWS S3 SDK（Gerrit LFS 使用）默认为 HTTPS，RustFS **必须**在直接访问时（不在 nginx 后）配置 SSL 证书。没有 HTTPS，Gerrit LFS 插件将失败，出现"unexpected EOF"或连接错误。

**注意：** 如果您无法在 RustFS 上配置 HTTPS，请使用带 HTTPS 的 nginx 反向代理作为替代解决方案。

SSL 证书生成过程与 MinIO 类似。请参考上面的 [生成 SSL 证书](#generate-ssl-certificates) 部分了解详细说明。

### 为 RustFS 创建凭据

1. **访问 RustFS 控制台：**
    - 在浏览器中打开 `http://localhost:9003`
    - 使用默认凭据登录：`rustfsadmin` / `rustfsadmin`

2. **创建存储桶：**
    - 导航到存储桶部分
    - 创建新存储桶（例如，`gerritlfs`）

3. **创建访问密钥（推荐用于生产环境）：**
    - 导航到访问密钥部分
    - 创建具有适当权限的新访问密钥
    - 保存访问密钥和密钥以供 Gerrit 配置使用

### 测试 RustFS 连接

您可以使用 MinIO 客户端 (`mc`) 或 AWS CLI 测试 RustFS，因为 RustFS 是 S3 兼容的：

#### 安装 MinIO 客户端

```bash
# 下载 MinIO 客户端
curl https://dl.min.io/client/mc/release/linux-amd64/mc -o mc
chmod +x mc
```

#### 配置 RustFS 别名

```bash
# 为您的 RustFS 服务器设置别名（如果配置了证书，使用 HTTPS）
mc alias set myrustfs http://localhost:9002 rustfsadmin rustfsadmin
```

#### 检查存储桶状态

```bash
# 列出所有存储桶
mc ls myrustfs

# 列出特定存储桶中的对象（例如，gerritlfs）
mc ls myrustfs/gerritlfs

# 获取详细的存储桶信息
mc stat myrustfs/gerritlfs

# 统计存储桶中的对象数
mc ls --recursive myrustfs/gerritlfs | wc -l

# 获取存储桶大小和对象数
mc du myrustfs/gerritlfs
```

更多信息，请参考 [RustFS 文档](https://docs.rustfs.com/)。

## 使用

```bash
# 克隆仓库
git clone http://127.0.0.1:8080/a/test-repo
cd test-repo

# 配置 LFS
git config lfs.url http://127.0.0.1:8080/a/test-repo/info/lfs
git config credential.helper store

# 对于自签名证书，将证书添加到系统信任存储（推荐）
# 这是必需的，因为 git-lfs 使用预签名 URL 直接上传到 MinIO
# 并且默认不信任自签名证书
#
# 步骤 1：从 MinIO 服务器复制证书到本地机器
scp user@minio-server:/path/to/minio/certs/public.crt /tmp/minio.crt

# 步骤 2：将证书添加到系统信任存储
sudo cp /tmp/minio.crt /usr/local/share/ca-certificates/minio.crt
sudo update-ca-certificates

# 步骤 3：验证证书已添加
ls -la /etc/ssl/certs/ | grep minio

# 验证 LFS 已配置
git ls-remote http://127.0.0.1:8080/a/test-repo

# 跟踪将存储在 S3 后端（MinIO、RustFS 或 AWS S3）上的文件类型
# 文件将存储在 S3 兼容的存储服务器上
git lfs track "*.bin"
git lfs track "*.dat"
git add .gitattributes
git commit -m "Configure Git LFS tracking with S3 backend"

# 推送 LFS 文件（将存储在 S3 兼容的存储服务器上）
git add large-file.bin
git commit -m "Add large binary file (stored on S3 backend)"
git push origin HEAD:refs/for/master

# 验证 LFS 文件已上传到 S3 后端
# 文件应该在 S3 服务器上可访问
# - 对于 MinIO：在 http://localhost:9001 检查 MinIO 控制台
# - 对于 RustFS：在 http://localhost:9003 检查 RustFS 控制台
git lfs ls-files
```

## 故障排除

### 检查 LFS 日志

如果遇到 LFS 操作问题，请检查 Git LFS 日志：

```bash
# 查看最后一次 LFS 操作日志
git lfs logs last

# 查看所有 LFS 日志
git lfs logs

# 查看特定日志文件
cat .git/lfs/logs/YYYYMMDDTHHMMSS.XXXXXXXX.log
```

### 常见问题

1. **"LFS is not available for repository"**
   - 确保项目在 `All-Projects/refs/meta/config/lfs.config` 中配置
   - 对于顶级项目，使用特定项目名称（例如，`[lfs "project-name"]`）
   - 对于所有项目，使用正则表达式模式 `[lfs "^.*$"]`

2. **SSL/HTTPS 连接错误**
   - 确保 MinIO 或 RustFS 配置了 SSL 证书（参见 [生成 SSL 证书](#generate-ssl-certificates)）
   - **"certificate signed by unknown authority" 错误（git-lfs）：**
     - 当 git-lfs 不信任自签名证书时会发生此错误
     - **解决方案（推荐）：** 将证书添加到系统的信任存储：
       ```bash
       # 步骤 1：从 S3 服务器复制证书到本地机器
       # 对于 MinIO：
       scp user@minio-server:/path/to/minio/certs/public.crt /tmp/minio.crt
       # 对于 RustFS：
       scp user@rustfs-server:/path/to/rustfs/certs/public.crt /tmp/rustfs.crt

       # 步骤 2：将证书添加到系统信任存储
       sudo cp /tmp/minio.crt /usr/local/share/ca-certificates/minio.crt
       # 或对于 RustFS：
       sudo cp /tmp/rustfs.crt /usr/local/share/ca-certificates/rustfs.crt
       sudo update-ca-certificates

       # 步骤 3：验证证书已添加
       ls -la /etc/ssl/certs/ | grep minio
       # 或对于 RustFS：
       ls -la /etc/ssl/certs/ | grep rustfs
       ```
       之后，git-lfs 将信任证书，您可以推送而不会出错。
     - **替代方案（仅用于测试）：** 环境变量或 git 配置（可能不适用于所有 git-lfs 版本）：
       ```bash
       export GIT_LFS_SKIP_SSL_VERIFY=1
       # 或
       git config lfs.https://minio_ip:9000/.sslverify false
       # 或对于 RustFS：
       git config lfs.https://rustfs_ip:9002/.sslverify false
       ```
       **注意：** 这些方法可能无法在 git-lfs 3.4+ 中可靠工作。添加到信任存储是推荐的解决方案。
   - 使用自签名证书时，验证 `lfs.config` 中的 `disableSslVerify = true`（这仅影响 Gerrit 的连接，不影响 git-lfs）
   - 检查 `lfs.config` 中的主机名是否不包含 `http://` 或 `https://` 前缀

3. **空 S3 存储桶（MinIO 或 RustFS）**
   - 验证文件是否由 Git LFS 跟踪：`git lfs ls-files`
   - 检查 `.gitattributes` 是否存在并跟踪您使用的文件类型
   - 确保 LFS 文件实际上正在被推送（不仅仅是常规 git 文件）

4. **连接被拒绝或未知主机**
   - 验证 S3 服务器正在运行：
     - 对于 MinIO：`docker-compose ps` 或 `docker ps | grep minio`
     - 对于 RustFS：`docker ps | grep rustfs`
   - 测试连接：
     - MinIO 直接访问：`curl -k https://YOUR_HOSTNAME:9000/minio/health/live`
     - RustFS 直接访问：`curl -k https://YOUR_HOSTNAME:9002/health/live`（如果健康端点可用）
     - 通过 nginx：`curl -k https://YOUR_DOMAIN/health/live`
   - 检查防火墙规则和 Gerrit 与 S3 服务器之间的网络连接
   - 如果使用 nginx 反向代理，验证 nginx 正在运行并正确配置

5. **"UnknownHostException: https: Name or service not known" 错误**
   - 当主机名包含协议前缀（`http://` 或 `https://`）时会发生此错误
   - **解决方案：** 从 `lfs.config` 中的 `hostname` 删除协议前缀
     - ❌ 错误：`hostname = https://your-domain.com`
     - ✅ 正确：`hostname = your-domain.com`
   - 如果使用 nginx 反向代理，确保主机名仅为域名（无路径前缀）
     - ❌ 错误：`hostname = your-domain.com/minio/api` 或 `hostname = your-domain.com/rustfs/api`
     - ✅ 正确：`hostname = your-domain.com`
     - 配置 nginx 在根路径 (`/`) 提供 S3 API，而不是子路径

## 参考

- [dev-buck](https://gerrit-documentation.storage.googleapis.com/Documentation/2.13/dev-buck.html)
- [gerrit-ci-plugin-lfs](https://gerrit-ci.gerritforge.com/job/plugin-lfs-bazel-master/lastSuccessfulBuild/console)
- [gerrit-plugins](https://www.gerritcodereview.com/plugins.html)
- [git-lfs](https://git-lfs.com)
- [lfs-build](https://gerrit.googlesource.com/plugins/lfs/+/refs/heads/stable-2.13/src/main/resources/Documentation/build.md)
- [lfs-config](https://gerrit.googlesource.com/plugins/lfs/+/refs/heads/master/src/main/resources/Documentation/config.md)
- [minio-s3](https://github.com/craftslab/minio)
- [rustfs-s3](https://github.com/craftslab/rustfs)
