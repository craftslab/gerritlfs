# gerritlfs

[English](./README.md) | [简体中文](./README_cn.md)

## 概述

- [2.13](https://github.com/craftslab/gerritlfs/tree/main/2.13) - Gerrit 2.13 版本构建文件
- [3.4](https://github.com/craftslab/gerritlfs/tree/main/3.4) - Gerrit 3.4 版本构建文件

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

#### 对于 Gerrit 3.4

1. **使用 Docker 构建插件：**

```bash
cd 3.4
./build.sh
```

这将创建一个包含已构建插件的 Docker 镜像 `gerrit-plugins-lfs:3.4`。

2. **从 Docker 容器中提取 lfs.jar：**

```bash
# 运行容器以构建插件
docker run --name gerrit-plugins-lfs gerrit-plugins-lfs:3.4

# 从容器复制 lfs.jar
docker cp gerrit-plugins-lfs:/workspace/output/lfs.jar ./lfs.jar

# 删除容器
docker rm gerrit-plugins-lfs
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
# 运行容器以构建插件
docker run --name gerrit-plugins-lfs gerrit-plugins-lfs:2.13

# 从容器复制 lfs.jar
docker cp gerrit-plugins-lfs:/workspace/lfs-2.13/buck-out/gen/lfs.jar ./lfs.jar

# 删除容器
docker rm gerrit-plugins-lfs
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
[auth]
    gitBasicAuth = true
```

**Gerrit 2.13 重要提示：**
- `auth.gitBasicAuth = true` 设置是**必需的**，以便 LFS HTTP 基本身份验证正常工作
- 没有此设置，Git LFS 客户端将无法与 Gerrit 进行身份验证

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

**Gerrit 2.13 特别说明：**
- Gerrit 2.13 使用 JGit LFS 4.5.0，该版本不原生支持自定义端点
- 插件会尝试使用 `hostname` 配置，但由于库的限制，您**必须**在 Gerrit 服务器和客户端机器上使用 `/etc/hosts` 映射
- **必需：** 对于 Gerrit 2.13，`accessKey` 和 `secretKey`**必须**直接放在 `lfs.config` 中（而不是 `lfs.secure.config`），因为 Gerrit 2.13.9 的 `PluginConfigFactory` 不会正确合并安全配置文件
- 在 Gerrit 服务器和客户端机器的 `/etc/hosts` 中添加：
  ```
  YOUR_RUSTFS_IP  your-domain.com s3-us-east-1.amazonaws.com
  ```
- 配置 nginx 接受两个主机名

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

**Gerrit 2.13 重要提示：** 对于 Gerrit 2.13，`accessKey` 和 `secretKey`**必须**直接放在 `lfs.config` 中（而不是 `lfs.secure.config`），因为 Gerrit 2.13.9 的 `PluginConfigFactory` 不会正确合并安全配置文件。请参见上面的 RustFS 配置示例以了解正确的格式。

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

### Gerrit 2.13 特殊配置

**重要提示：** Gerrit 2.13 使用 JGit LFS 4.5.0，该版本在自定义 S3 端点方面有限制。需要额外配置：

1. **在 `lfs.config` 中的凭据（必需）：**
   - 对于 Gerrit 2.13，`accessKey` 和 `secretKey`**必须**直接放在 `lfs.config` 中（而不是 `lfs.secure.config`）
   - 这是因为 Gerrit 2.13.9 的 `PluginConfigFactory` 不会正确合并安全配置文件
   - 示例：
     ```
     [s3 "rustfs"]
         hostname = your-domain.com
         region = us-east-1
         bucket = gerritlfs
         storageClass = REDUCED_REDUNDANCY
         expirationSeconds = 60
         disableSslVerify = true
         accessKey = YOUR_ACCESS_KEY
         secretKey = YOUR_SECRET_KEY
     ```

2. **服务器端 `/etc/hosts` 映射（必需）：**
   ```bash
   # 在 Gerrit 服务器上
   echo "YOUR_S3_SERVER_IP  your-domain.com s3-us-east-1.amazonaws.com" | sudo tee -a /etc/hosts
   ```

3. **客户端 `/etc/hosts` 映射（必需）：**
   ```bash
   # 在客户端机器上（运行 git push 的地方）
   echo "YOUR_S3_SERVER_IP  your-domain.com s3-us-east-1.amazonaws.com" | sudo tee -a /etc/hosts
   ```

4. **Nginx 配置（使用反向代理时必需）：**
   - 必须接受两个主机名：`server_name your-domain.com s3-us-east-1.amazonaws.com;`
   - 必须保留原始 Host 头：`proxy_set_header Host $http_host;`
   - 参见上面的 nginx 配置示例

5. **客户端 git-lfs SSL 配置（必需）：**
   ```bash
   # 由于证书主机名不匹配，跳过 SSL 验证
   # 注意：git-lfs 3.4+ 中，sslverify 配置可能不可靠，推荐使用环境变量
   export GIT_SSL_NO_VERIFY=1
   # 或使用 GIT_LFS_SKIP_SSL_VERIFY（git-lfs 专用）
   export GIT_LFS_SKIP_SSL_VERIFY=1
   # 或尝试配置（在 git-lfs 3.4+ 中可能不工作）
   git config lfs.https://s3-us-east-1.amazonaws.com/.sslverify false
   ```

6. **禁用 S3 端点的代理（如果使用代理）：**

   **选项 1：清空代理环境变量（如果不需要代理，推荐）：**
   ```bash
   export https_proxy=
   export http_proxy=
   export HTTPS_PROXY=
   export HTTP_PROXY=
   ```

   **选项 2：将 S3 端点添加到 no_proxy：**
   ```bash
   export no_proxy="your-domain.com,s3-us-east-1.amazonaws.com,YOUR_S3_SERVER_IP,localhost,127.0.0.1"
   ```

   **注意：** 如果您在推送 LFS 文件时遇到 EOF 错误，请先尝试清空代理环境变量。Git LFS 可能会尝试使用代理进行 S3 连接，即使配置了 `/etc/hosts` 映射也可能导致连接失败。

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
   curl -k https://YOUR_HOSTNAME_OR_IP:9000/minio/health

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

**对于 Gerrit 2.13：** nginx 配置必须接受您的自定义域名和 `s3-us-east-1.amazonaws.com` 作为服务器名称，以支持预签名 URL。请参见下面的配置。

```nginx
server {
    listen 80;
    server_name your-domain.com s3-us-east-1.amazonaws.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name your-domain.com s3-us-east-1.amazonaws.com;

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
- **对于 Gerrit 2.13：** `server_name` 必须包含您的域名和 `s3-us-east-1.amazonaws.com`，并且必须保留 `Host` 头（如上所示）才能使 S3 签名验证正常工作

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

## 自动化设置脚本

### 使用 git-lfs.sh

为了更轻松地设置和配置，您可以使用提供的 `git-lfs.sh` 脚本来自动化 Git LFS 配置过程。

**功能特性：**
- 自动化 Git LFS 安装和配置
- 将 S3 证书安装到系统信任存储
- 在 `/etc/hosts` 中配置 S3 主机映射
- 为 LFS 操作配置禁用 SSL 验证的 Git 别名
- 轻松清理所有配置

**使用方法：**

```bash
# 使脚本可执行
chmod +x git-lfs.sh

# 检查当前配置状态
./git-lfs.sh check

# 配置 Git LFS（安装 git-lfs、S3 证书、主机映射和 git 别名）
./git-lfs.sh config

# 清理所有配置（删除 git-lfs、证书、主机映射和别名）
./git-lfs.sh clean

# 显示版本
./git-lfs.sh version

# 显示帮助
./git-lfs.sh help
```

**`git-lfs.sh config` 执行的操作：**

1. **安装 Git LFS：**
   - 选项 1：通过 apt 安装（推荐）
   - 选项 2：从 Artifactory 下载

2. **配置 S3 证书：**
   - 下载 S3 服务器证书
   - 将其安装到 `/usr/local/share/ca-certificates/`
   - 更新系统 CA 证书

3. **配置 S3 主机映射：**
   - 将 S3 服务器 IP 和主机名映射添加到 `/etc/hosts`
   - 支持自定义 S3 端点

4. **配置 Git 别名：**
   - 设置便捷的 git 别名，禁用 SSL 验证：
     - `git push-lfs`：支持 LFS 的推送
     - `git clone-lfs`：支持 LFS 的克隆
     - `git fetch-lfs`：获取 LFS 对象
     - `git checkout-lfs`：检出 LFS 文件
     - `git pull-lfs`：支持 LFS 的拉取
   - 配置凭据助手以存储凭据

**示例工作流：**

```bash
# 1. 配置环境
./git-lfs.sh config

# 2. 使用 git 别名进行 LFS 操作
git clone-lfs http://gerrit-server:8080/a/my-repo
cd my-repo
git push-lfs origin HEAD:refs/for/master
```

**注意：** 该脚本自动化了[前置要求](#前置要求)和[配置](#配置)部分中描述的手动配置步骤。运行 `./git-lfs.sh config` 后，您可以跳过手动 SSL 证书和 `/etc/hosts` 配置步骤。

### 使用 migrate.sh

用于在源和目标之间迁移 Git LFS 仓库并同步 S3 存储桶数据，您可以使用提供的 `migrate.sh` 脚本。

**功能特性：**
- 克隆或获取 Git LFS 仓库，支持特定提交日期
- 从源存储服务器下载 S3 存储桶数据
- 将 S3 存储桶数据上传到目标存储服务器
- 将仓库和 LFS 对象推送到目标仓库
- 按提交日期过滤 S3 对象，仅下载相关的 LFS 文件
- 支持增量迁移和部分操作

**前置要求：**
- `git` - Git 版本控制
- `git-lfs` - Git LFS 扩展
- `aws-cli` - 用于 S3 操作的 AWS CLI

在 Ubuntu 上安装：
```bash
sudo apt-get install git git-lfs awscli
```

**使用方法：**

```bash
# 使脚本可执行
chmod +x migrate.sh

# 配置迁移设置（交互式）
./migrate.sh config

# 执行完整迁移（克隆/获取、下载 S3、上传 S3、推送）
./migrate.sh migrate

# 仅克隆或获取源仓库
./migrate.sh clone

# 仅从源下载 S3 存储桶数据
./migrate.sh fetch-s3

# 仅将 S3 存储桶数据上传到目标
./migrate.sh upload-s3

# 仅将仓库推送到目标
./migrate.sh push

# 检查依赖项和配置
./migrate.sh check

# 显示版本
./migrate.sh version

# 显示帮助
./migrate.sh help
```

**配置：**

脚本使用交互式配置向导，或者您可以直接编辑配置文件：

```bash
# 交互式配置
./migrate.sh config
```

配置保存在 `~/.git-lfs-migrate.conf`。您也可以直接编辑此文件：

```bash
# 源 Git 仓库
SOURCE_GIT_URL="http://source-gerrit:8080/a/my-repo"
SOURCE_GIT_BRANCH="master"
SOURCE_COMMIT_HASH=""  # 可选：特定提交哈希
SOURCE_COMMIT_DATE=""   # 可选：日期字符串（例如："2024-01-01" 或 "2024-01-01 12:00:00"）

# 源 S3 配置
SOURCE_S3_ENDPOINT="https://source-s3.example.com"
SOURCE_S3_BUCKET="gerritlfs"
SOURCE_S3_ACCESS_KEY="your-access-key"
SOURCE_S3_SECRET_KEY="your-secret-key"
SOURCE_S3_REGION="us-east-1"

# 目标 Git 仓库
DEST_GIT_URL="http://dest-gerrit:8080/a/my-repo"
DEST_GIT_BRANCH="master"

# 目标 S3 配置
DEST_S3_ENDPOINT="https://dest-s3.example.com"
DEST_S3_BUCKET="gerritlfs"
DEST_S3_ACCESS_KEY="your-access-key"
DEST_S3_SECRET_KEY="your-secret-key"
DEST_S3_REGION="us-east-1"

# 迁移选项
WORK_DIR="/tmp/git-lfs-migrate"
SKIP_S3_SYNC="false"
SKIP_GIT_PUSH="false"
```

**提交日期支持：**

您可以指定特定的提交日期或哈希值，以在特定时间点迁移仓库：

```bash
# 使用提交日期配置
./migrate.sh config
# 提示时输入：
# Source Commit Hash: （可选，例如：abc123def）
# Source Commit Date: 2024-01-01

# 或在配置文件中设置：
SOURCE_COMMIT_DATE="2024-01-01"
SOURCE_COMMIT_HASH="abc123def"
```

当指定提交日期时：
- 仓库将检出到该日期或之前的提交
- 仅下载该提交引用的 LFS 对象
- 这允许基于时间的迁移并减少下载大小

**示例工作流：**

```bash
# 1. 配置迁移设置
./migrate.sh config

# 2. 执行完整迁移
./migrate.sh migrate

# 或分步执行：
# 2a. 克隆源仓库
./migrate.sh clone

# 2b. 下载 S3 存储桶数据
./migrate.sh fetch-s3

# 2c. 将 S3 存储桶数据上传到目标
./migrate.sh upload-s3

# 2d. 推送到目标仓库
./migrate.sh push
```

**使用特定提交日期进行迁移：**

```bash
# 使用提交日期配置
./migrate.sh config
# 输入提交日期：2024-01-01

# 执行迁移 - 仅下载该提交的 LFS 对象
./migrate.sh migrate
```

**环境变量：**

您还可以设置环境变量来覆盖配置：

```bash
export GIT_SSL_NO_VERIFY=1          # 跳过 Git 操作的 SSL 验证
export GIT_LFS_SKIP_SSL_VERIFY=1    # 跳过 Git LFS 操作的 SSL 验证
export AWS_ACCESS_KEY_ID="..."       # AWS 访问密钥（如果不在配置中）
export AWS_SECRET_ACCESS_KEY="..."  # AWS 密钥（如果不在配置中）
```

**注意：** 脚本会自动处理自签名证书的 SSL 验证跳过，并支持直接 S3 访问和 S3 兼容的存储服务器（MinIO、RustFS 等）。

## 使用

### 克隆和推送 LFS 文件至 S3 存储

```bash
# 克隆仓库
git clone http://127.0.0.1:8080/a/test-repo
cd test-repo

# 存储 credential (~/.git-credentials)
git config --global credential.helper store

# 对于自签名证书或自定义主机名（Gerrit 2.13），配置 git-lfs SSL 验证
# 这是必需的，因为 git-lfs 使用预签名 URL 直接上传到 S3
# 并且默认不信任自签名证书或不匹配的主机名
#
# 选项 1：跳过 S3 端点的 SSL 验证（用于测试或使用 /etc/hosts 映射时）
export GIT_SSL_NO_VERIFY=1
# 或
git config lfs.https://s3-us-east-1.amazonaws.com/.sslverify false

# 选项 2：将证书添加到系统信任存储（推荐用于生产环境）
# 步骤 1：从 S3 服务器复制证书到本地机器
# 对于 MinIO：
scp user@minio-server:/path/to/minio/certs/public.crt /tmp/minio.crt
# 对于 RustFS：
scp user@rustfs-server:/path/to/rustfs/certs/public.crt /tmp/rustfs.crt

# 选项 3：设置本地 git 别名用于推送时禁用 SSL 验证（推荐）
# 这会在 .git/config 中创建本地别名（不是全局），因此仅影响此仓库
# 注意：在 git-lfs 3.4+ 中，sslverify 配置可能不可靠，因此推荐使用带环境变量的别名
git config --global alias.push-lfs '!GIT_SSL_NO_VERIFY=1 GIT_LFS_SKIP_SSL_VERIFY=1 git push'

# 步骤 2：将证书添加到系统信任存储
sudo cp /tmp/minio.crt /usr/local/share/ca-certificates/minio.crt
# 或对于 RustFS：
sudo cp /tmp/rustfs.crt /usr/local/share/ca-certificates/rustfs.crt
sudo update-ca-certificates

# 步骤 3：验证证书已添加
ls -la /etc/ssl/certs/ | grep minio
# 或对于 RustFS：
ls -la /etc/ssl/certs/ | grep rustfs

# 对于 Gerrit 2.13：还要在客户端机器上添加 /etc/hosts 映射
echo "YOUR_S3_SERVER_IP  your-domain.com s3-us-east-1.amazonaws.com" | sudo tee -a /etc/hosts

# 验证 LFS 已配置
git ls-remote http://127.0.0.1:8080/a/test-repo

# 在仓库中创建 .lfsconfig 文件（推荐）
# 此文件会被提交到仓库中，并自动为所有用户配置 LFS URL
# 当有人克隆仓库时，git-lfs 会自动使用 .lfsconfig 中的 URL
# 这样就不需要每个用户手动配置 lfs.url
git config -f .lfsconfig lfs.url http://127.0.0.1:8080/a/test-repo/info/lfs
git add .lfsconfig

# 跟踪将存储在 S3 后端（MinIO、RustFS 或 AWS S3）上的文件类型
# 文件将存储在 S3 兼容的存储服务器上
git lfs track "*.bin"
git lfs track "*.dat"
git add .gitattributes
git commit -m "Configure Git LFS tracking with S3 backend"

# 推送 LFS 文件（将存储在 S3 兼容的存储服务器上）
git add large-file.bin
git commit -m "Add large binary file (stored on S3 backend)"

# 使用别名推送（自动为 git-lfs 设置 GIT_SSL_NO_VERIFY=1）
git push-lfs origin HEAD:refs/for/master

# 或正常推送（需要在环境中设置 GIT_SSL_NO_VERIFY=1）
# git push origin HEAD:refs/for/master

# 验证 LFS 文件已上传到 S3 后端
# 文件应该在 S3 服务器上可访问
# - 对于 MinIO：在 http://localhost:9001 检查 MinIO 控制台
# - 对于 RustFS：在 http://localhost:9003 检查 RustFS 控制台
git lfs ls-files
```

### 从 S3 存储克隆和拉取 LFS 文件

当克隆或拉取已包含存储在 S3 中的 LFS 文件的仓库时，需要配置 git-lfs 以访问 S3 存储后端：

```bash
# 克隆包含 LFS 文件的仓库
git clone http://127.0.0.1:8080/a/test-repo
cd test-repo

# 配置 LFS URL（LFS 操作所必需）
git config lfs.url http://127.0.0.1:8080/a/test-repo/info/lfs

# 存储凭据以进行身份验证
git config credential.helper store

# 对于 Gerrit 2.13：在客户端机器上配置 /etc/hosts 映射（必需）
# 这是必需的，因为 Gerrit 2.13 使用 JGit LFS 4.5.0，它从区域构造
# S3 端点，而不是使用配置的主机名
echo "YOUR_S3_SERVER_IP  your-domain.com s3-us-east-1.amazonaws.com" | sudo tee -a /etc/hosts

# 为 S3 端点配置 git-lfs SSL 验证
# 这是必需的，因为 git-lfs 使用预签名 URL 直接从 S3 下载
# 并且默认不信任自签名证书或不匹配的主机名
#
# 选项 1：跳过 SSL 验证（用于测试或使用 /etc/hosts 映射时）
export GIT_SSL_NO_VERIFY=1
# 或
export GIT_LFS_SKIP_SSL_VERIFY=1
# 或
git config lfs.https://s3-us-east-1.amazonaws.com/.sslverify false

# 选项 2：将证书添加到系统信任存储（推荐用于生产环境）
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

# 从 S3 存储拉取 LFS 文件
# Git LFS 会在您检出或拉取时自动下载 LFS 文件
git checkout master
# 或
git pull origin master

# 验证 LFS 文件已下载
git lfs ls-files

# 检查 LFS 文件状态
git lfs status

# 如果 LFS 文件未自动下载，请手动获取它们：
git lfs fetch
git lfs checkout
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
       # 方法 1：使用环境变量（推荐，在 git-lfs 3.4+ 中可靠）
       export GIT_SSL_NO_VERIFY=1
       # 或
       export GIT_LFS_SKIP_SSL_VERIFY=1

       # 方法 2：尝试配置（在 git-lfs 3.4+ 中可能不工作）
       git config lfs.https://minio_ip:9000/.sslverify false
       # 或对于 RustFS：
       git config lfs.https://rustfs_ip:9002/.sslverify false

       # 方法 3：尝试设置 git 别名
       git config alias.push-lfs '!GIT_SSL_NO_VERIFY=1 GIT_LFS_SKIP_SSL_VERIFY=1 git push'
       ```
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
     - MinIO 直接访问：`curl -k https://YOUR_HOSTNAME:9000/minio/health`
     - RustFS 直接访问：`curl -k https://YOUR_HOSTNAME:9002/health`（如果健康端点可用）
     - 通过 nginx：`curl -k https://YOUR_DOMAIN/health`
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

6. **"UnknownHostException: s3-us-east-1.amazonaws.com: Name or service not known"（Gerrit 2.13）**
   - **问题：** Gerrit 2.13 使用 JGit LFS 4.5.0，该版本不原生支持自定义端点。S3 客户端从区域构造端点（例如，`s3-us-east-1.amazonaws.com`），而不是使用配置的 `hostname`。
   - **解决方案：** 在 Gerrit 服务器和客户端机器上使用 `/etc/hosts` 映射：
     ```bash
     # 在 Gerrit 服务器上
     echo "YOUR_RUSTFS_IP  your-domain.com s3-us-east-1.amazonaws.com" | sudo tee -a /etc/hosts

     # 在客户端机器上（运行 git push 的地方）
     echo "YOUR_RUSTFS_IP  your-domain.com s3-us-east-1.amazonaws.com" | sudo tee -a /etc/hosts
     ```
   - **还需要：**
     - 配置 nginx 接受 `s3-us-east-1.amazonaws.com` 作为服务器名称（参见上面的 nginx 配置）
     - 配置 nginx 保留原始 `Host` 头以进行 S3 签名验证
     - 配置 git-lfs 跳过 SSL 验证（证书不匹配）：
       ```bash
       # 方法 1：使用环境变量（推荐，在 git-lfs 3.4+ 中可靠）
       export GIT_SSL_NO_VERIFY=1
       # 或
       export GIT_LFS_SKIP_SSL_VERIFY=1

       # 方法 2：尝试配置（在 git-lfs 3.4+ 中可能不工作）
       git config lfs.https://s3-us-east-1.amazonaws.com/.sslverify false

       # 方法 3：尝试设置 git 别名
       git config alias.push-lfs '!GIT_SSL_NO_VERIFY=1 GIT_LFS_SKIP_SSL_VERIFY=1 git push'
       ```
     - **清空代理环境变量（如果代理导致问题）：**
       ```bash
       export https_proxy=
       export http_proxy=
       export HTTPS_PROXY=
       export HTTP_PROXY=
       ```

7. **"LFS: Put ... EOF" 错误（Gerrit 2.13）**
   - **问题：** 即使在配置了 `/etc/hosts` 映射后，推送文件时 Git LFS 上传仍失败并出现 EOF 错误。
   - **解决方案：** 清空代理环境变量。Git LFS 可能会尝试使用系统代理进行 S3 连接，这可能会干扰 `/etc/hosts` 映射：
     ```bash
     # 清空所有代理环境变量
     export https_proxy=
     export http_proxy=
     export HTTPS_PROXY=
     export HTTP_PROXY=

     # 然后重试 git push
     git push origin HEAD:refs/for/master
     ```
   - **替代方案：** 如果您需要为其他服务保留代理，请将 S3 端点添加到 `no_proxy`：
     ```bash
     export no_proxy="your-domain.com,s3-us-east-1.amazonaws.com,YOUR_S3_SERVER_IP,localhost,127.0.0.1"
     ```

8. **"SignatureDoesNotMatch" 错误（Gerrit 2.13 与 RustFS/MinIO）**
   - **问题：** S3 预签名 URL 在签名中包含主机名。当 Gerrit 为 `s3-us-east-1.amazonaws.com` 生成 URL 但请求发送到您的自定义域名时，签名验证失败。
   - **解决方案：**
     - 配置 nginx 保留原始 `Host` 头：`proxy_set_header Host $http_host;`
     - 确保 nginx 接受两个主机名：`server_name your-domain.com s3-us-east-1.amazonaws.com;`
     - 确保 `/etc/hosts` 映射在服务器和客户端上都正确
   - 如果错误仍然存在，请检查 RustFS/MinIO 日志以获取详细的签名验证错误

9. **将 lfs.config 添加到 All-Projects.git 裸仓库（Gerrit 2.13）**
   - **问题：** 当由于权限问题（例如，"You are not allowed to perform this operation"）无法通过 HTTP 推送 `lfs.config` 时，需要直接在服务器上的裸仓库中添加它。
   - **解决方案：** 使用 `2.13/` 目录中提供的 `transfer-commit.sh` 脚本。
   - **步骤：**
     1. **准备您的 lfs.config 文件：**
        ```bash
        # 创建或编辑您的 lfs.config 文件
        cd ~/my-tmp/google-gerrit/All-Projects-2.13.4
        # 使用您的配置编辑 lfs.config
        nano lfs.config
        ```
     2. **创建临时工作仓库：**
        ```bash
        cd /tmp
        mkdir fix-gerrit && cd fix-gerrit
        git clone ~/my-tmp/google-gerrit/install-2.13.4/git/All-Projects.git temp-repo
        cd temp-repo
        ```
     3. **检出 refs/meta/config 并添加 lfs.config：**
        ```bash
        git fetch origin refs/meta/config:refs/meta/config
        git checkout refs/meta/config
        cp ~/my-tmp/google-gerrit/All-Projects-2.13.4/lfs.config .
        git add lfs.config
        git commit -m "Add lfs.config for Git LFS configuration"
        NEW_COMMIT=$(git rev-parse HEAD)
        ```
     4. **使用 transfer-commit.sh 将提交传输到裸仓库：**
        ```bash
        # 将脚本复制到您的工作目录
        cp ~/my-tmp/gerritlfs/2.13/transfer-commit.sh .

        # 编辑脚本以设置正确的路径：
        # - TEMP_REPO: 您的 temp-repo 路径（例如，/tmp/fix-gerrit/temp-repo）
        # - BARE_REPO: All-Projects.git 裸仓库路径
        # - NEW_COMMIT: 步骤 3 中的提交哈希

        # 运行脚本
        bash transfer-commit.sh
        ```
     - **脚本的作用：**
       - 尝试直接从 temp-repo 推送到裸仓库（最可靠）
       - 如果推送失败，回退到获取对象
       - 如果获取失败，回退到直接复制 Git 对象
       - 更新裸仓库中的 `refs/meta/config`
       - 验证 `lfs.config` 存在并显示其内容
   - **替代快速方法：**
     ```bash
     # 从 temp-repo 直接推送到裸仓库
     cd /tmp/fix-gerrit/temp-repo
     git push ~/my-tmp/google-gerrit/install-2.13.4/git/All-Projects.git refs/meta/config:refs/meta/config

     # 验证
     cd ~/my-tmp/google-gerrit/install-2.13.4/git/All-Projects.git
     git show refs/meta/config:lfs.config
     ```
   - **添加 lfs.config 后：**
     - 重启 Gerrit 以加载新配置：`systemctl restart gerrit`
     - 配置将被所有项目继承
     - 通过向项目推送大文件来测试 LFS 功能

## 参考

- [dev-buck](https://gerrit-documentation.storage.googleapis.com/Documentation/2.13/dev-buck.html)
- [gerrit-ci-plugin-lfs](https://gerrit-ci.gerritforge.com/job/plugin-lfs-bazel-master/lastSuccessfulBuild/console)
- [gerrit-plugins](https://www.gerritcodereview.com/plugins.html)
- [git-lfs](https://git-lfs.com)
- [lfs-build](https://gerrit.googlesource.com/plugins/lfs/+/refs/heads/stable-2.13/src/main/resources/Documentation/build.md)
- [lfs-config](https://gerrit.googlesource.com/plugins/lfs/+/refs/heads/master/src/main/resources/Documentation/config.md)
- [minio-s3](https://github.com/craftslab/minio)
- [rustfs-s3](https://github.com/craftslab/rustfs)
