#!/bin/bash

# Git LFS Repository Migration Script
# Supports cloning/fetching git LFS repositories and syncing S3 bucket data
# between source and destination repositories and S3 storage servers

# Script version
SCRIPT_VERSION="1.0.0-rc1"

# Terminal colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'  # No Color

# Default configuration file
CONFIG_FILE="${HOME}/.git-lfs-migrate.conf"

# Check if required commands are installed
check_dependencies() {
    local missing_deps=()

    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
    fi

    if ! command -v git-lfs &> /dev/null; then
        missing_deps+=("git-lfs")
    fi

    if ! command -v aws &> /dev/null; then
        missing_deps+=("aws-cli")
    fi

    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo -e "${RED}ERROR${NC}: Missing required dependencies: ${missing_deps[*]}"
        echo -e "${BLUE}INFO${NC}: Please install missing dependencies:"
        for dep in "${missing_deps[@]}"; do
            case "$dep" in
                "git")
                    echo -e "   - git: sudo apt-get install git"
                    ;;
                "git-lfs")
                    echo -e "   - git-lfs: sudo apt-get install git-lfs"
                    ;;
                "aws-cli")
                    echo -e "   - aws-cli: Install via one of the following (Ubuntu 24.04 has no apt awscli):"
                    echo -e "     Option 1 (Snap): sudo snap install aws-cli --classic"
                    echo -e "     Option 2 (apt, if available): sudo apt-get install awscli"
                    echo -e "     Option 3 (Official installer): curl -s https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o /tmp/awscliv2.zip && (cd /tmp && unzip -o awscliv2.zip && sudo ./aws/install)"
                    ;;
            esac
        done
        return 1
    fi

    echo -e "${GREEN}OK${NC}: All required dependencies are installed"
    return 0
}

# Load configuration from file
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        echo -e "${BLUE}INFO${NC}: Configuration loaded from ${CONFIG_FILE}"
    else
        echo -e "${YELLOW}WARNING${NC}: Configuration file not found: ${CONFIG_FILE}"
        echo -e "${BLUE}INFO${NC}: Using command-line arguments or defaults"
    fi
}

# Save configuration to file
save_config() {
    cat > "$CONFIG_FILE" << EOF
# Git LFS Migration Configuration
# Generated on $(date)

# Source Git Repository
SOURCE_GIT_URL="${SOURCE_GIT_URL}"
SOURCE_GIT_BRANCH="${SOURCE_GIT_BRANCH:-master}"

# Source S3 Configuration
SOURCE_S3_ENDPOINT="${SOURCE_S3_ENDPOINT}"
SOURCE_S3_BUCKET="${SOURCE_S3_BUCKET}"
SOURCE_S3_ACCESS_KEY="${SOURCE_S3_ACCESS_KEY}"
SOURCE_S3_SECRET_KEY="${SOURCE_S3_SECRET_KEY}"
SOURCE_S3_REGION="${SOURCE_S3_REGION:-us-east-1}"

# Destination Git Repository
DEST_GIT_URL="${DEST_GIT_URL}"
DEST_GIT_BRANCH="${DEST_GIT_BRANCH:-master}"

# Destination S3 Configuration
DEST_S3_ENDPOINT="${DEST_S3_ENDPOINT}"
DEST_S3_BUCKET="${DEST_S3_BUCKET}"
DEST_S3_ACCESS_KEY="${DEST_S3_ACCESS_KEY}"
DEST_S3_SECRET_KEY="${DEST_S3_SECRET_KEY}"
DEST_S3_REGION="${DEST_S3_REGION:-us-east-1}"

# Migration Options
WORK_DIR="${WORK_DIR:-/tmp/git-lfs-migrate}"
SKIP_S3_SYNC="${SKIP_S3_SYNC:-false}"
SKIP_GIT_PUSH="${SKIP_GIT_PUSH:-false}"
SOURCE_COMMIT_DATE="${SOURCE_COMMIT_DATE}"
SOURCE_COMMIT_HASH="${SOURCE_COMMIT_HASH}"
EOF
    echo -e "${GREEN}OK${NC}: Configuration saved to ${CONFIG_FILE}"
}

# Configure source and destination
configure_migration() {
    echo -e "${BLUE}INFO${NC}: Configuring Git LFS migration..."
    echo ""

    # Source Git Repository
    read -p "Source Git Repository URL: " SOURCE_GIT_URL
    if [ -z "$SOURCE_GIT_URL" ]; then
        echo -e "${RED}ERROR${NC}: Source Git URL is required"
        return 1
    fi

    read -p "Source Git Branch (default: master): " SOURCE_GIT_BRANCH
    SOURCE_GIT_BRANCH="${SOURCE_GIT_BRANCH:-master}"

    # Source S3 Configuration
    echo ""
    echo -e "${BLUE}INFO${NC}: Source S3 Configuration:"
    read -p "Source S3 Endpoint (e.g., https://s3.example.com or https://localhost:9000): " SOURCE_S3_ENDPOINT
    if [ -z "$SOURCE_S3_ENDPOINT" ]; then
        echo -e "${RED}ERROR${NC}: Source S3 endpoint is required"
        return 1
    fi

    read -p "Source S3 Bucket: " SOURCE_S3_BUCKET
    if [ -z "$SOURCE_S3_BUCKET" ]; then
        echo -e "${RED}ERROR${NC}: Source S3 bucket is required"
        return 1
    fi

    read -p "Source S3 Access Key: " SOURCE_S3_ACCESS_KEY
    read -p "Source S3 Secret Key: " -s SOURCE_S3_SECRET_KEY
    echo ""

    read -p "Source S3 Region (default: us-east-1): " SOURCE_S3_REGION
    SOURCE_S3_REGION="${SOURCE_S3_REGION:-us-east-1}"

    # Destination Git Repository
    echo ""
    echo -e "${BLUE}INFO${NC}: Destination Git Repository:"
    read -p "Destination Git Repository URL: " DEST_GIT_URL
    if [ -z "$DEST_GIT_URL" ]; then
        echo -e "${RED}ERROR${NC}: Destination Git URL is required"
        return 1
    fi

    read -p "Destination Git Branch (default: master): " DEST_GIT_BRANCH
    DEST_GIT_BRANCH="${DEST_GIT_BRANCH:-master}"

    # Destination S3 Configuration
    echo ""
    echo -e "${BLUE}INFO${NC}: Destination S3 Configuration:"
    read -p "Destination S3 Endpoint (e.g., https://s3.example.com or https://localhost:9000): " DEST_S3_ENDPOINT
    if [ -z "$DEST_S3_ENDPOINT" ]; then
        echo -e "${RED}ERROR${NC}: Destination S3 endpoint is required"
        return 1
    fi

    read -p "Destination S3 Bucket: " DEST_S3_BUCKET
    if [ -z "$DEST_S3_BUCKET" ]; then
        echo -e "${RED}ERROR${NC}: Destination S3 bucket is required"
        return 1
    fi

    read -p "Destination S3 Access Key: " DEST_S3_ACCESS_KEY
    read -p "Destination S3 Secret Key: " -s DEST_S3_SECRET_KEY
    echo ""

    read -p "Destination S3 Region (default: us-east-1): " DEST_S3_REGION
    DEST_S3_REGION="${DEST_S3_REGION:-us-east-1}"

    # Work directory
    echo ""
    read -p "Working Directory (default: /tmp/git-lfs-migrate): " WORK_DIR
    WORK_DIR="${WORK_DIR:-/tmp/git-lfs-migrate}"

    # Commit date/hash for specific point in time
    echo ""
    echo -e "${BLUE}INFO${NC}: Optional - Clone/fetch specific commit or date:"
    read -p "Source Commit Hash (optional, e.g., abc123def): " SOURCE_COMMIT_HASH
    read -p "Source Commit Date (optional, e.g., '2024-01-01' or '2024-01-01 12:00:00'): " SOURCE_COMMIT_DATE

    # Save configuration
    save_config

    echo ""
    echo -e "${GREEN}OK${NC}: Configuration completed"
    return 0
}

# Clone or fetch source repository
clone_or_fetch_repo() {
    local repo_url="$1"
    local branch="$2"
    local work_dir="$3"
    local commit_hash="${4:-}"
    local commit_date="${5:-}"
    local repo_name=$(basename "$repo_url" .git)
    local repo_dir="${work_dir}/${repo_name}"

    echo -e "${BLUE}INFO${NC}: Cloning/fetching repository: ${repo_url}"

    if [ -d "$repo_dir" ]; then
        echo -e "${BLUE}INFO${NC}: Repository directory exists, fetching updates..."
        cd "$repo_dir" || return 1

        # Fetch all branches and tags to ensure we have the commit we need
        if ! git fetch --all --tags 2>&1; then
            echo -e "${YELLOW}WARNING${NC}: Failed to fetch all branches, trying branch only..."
            if ! git fetch origin "$branch" 2>&1; then
                echo -e "${RED}ERROR${NC}: Failed to fetch from repository"
                return 1
            fi
        fi

        # Checkout branch first
        if ! git checkout "$branch" 2>&1; then
            echo -e "${RED}ERROR${NC}: Failed to checkout branch: ${branch}"
            return 1
        fi
    else
        echo -e "${BLUE}INFO${NC}: Cloning repository..."
        mkdir -p "$work_dir"

        if ! git clone "$repo_url" "$repo_dir" 2>&1; then
            echo -e "${RED}ERROR${NC}: Failed to clone repository"
            return 1
        fi

        cd "$repo_dir" || return 1

        # Checkout specified branch
        if ! git checkout "$branch" 2>&1; then
            echo -e "${YELLOW}WARNING${NC}: Branch ${branch} not found, using default branch"
        fi
    fi

    # Handle specific commit date or hash
    local target_commit=""
    if [ -n "$commit_hash" ]; then
        echo -e "${BLUE}INFO${NC}: Checking out specific commit: ${commit_hash}"
        if git rev-parse --verify "$commit_hash" >/dev/null 2>&1; then
            target_commit="$commit_hash"
            if ! git checkout "$commit_hash" 2>&1; then
                echo -e "${RED}ERROR${NC}: Failed to checkout commit: ${commit_hash}"
                return 1
            fi
        else
            echo -e "${RED}ERROR${NC}: Commit hash not found: ${commit_hash}"
            return 1
        fi
    elif [ -n "$commit_date" ]; then
        echo -e "${BLUE}INFO${NC}: Finding commit at or before date: ${commit_date}"
        # Try to find commit by date
        local date_commit=$(git log --until="$commit_date" --format="%H" -n 1 2>/dev/null)
        if [ -n "$date_commit" ]; then
            target_commit="$date_commit"
            echo -e "${BLUE}INFO${NC}: Found commit: ${date_commit} (date: $(git log -1 --format='%ci' "$date_commit"))"
            if ! git checkout "$date_commit" 2>&1; then
                echo -e "${RED}ERROR${NC}: Failed to checkout commit: ${date_commit}"
                return 1
            fi
        else
            echo -e "${YELLOW}WARNING${NC}: No commit found at or before date: ${commit_date}, using current branch"
        fi
    else
        # Reset to remote branch if no specific commit
        if ! git reset --hard "origin/${branch}" 2>&1; then
            echo -e "${YELLOW}WARNING${NC}: Failed to reset to origin/${branch}, continuing..."
        fi
    fi

    # Initialize Git LFS
    if ! git lfs install --local >/dev/null 2>&1; then
        echo -e "${YELLOW}WARNING${NC}: Failed to initialize Git LFS locally"
    fi

    # Fetch LFS objects for current commit
    echo -e "${BLUE}INFO${NC}: Fetching Git LFS objects..."
    if [ -n "$target_commit" ]; then
        # Fetch LFS objects for specific commit
        if ! git lfs fetch origin "$target_commit" 2>&1; then
            echo -e "${YELLOW}WARNING${NC}: Failed to fetch LFS objects for commit, trying --all..."
            if ! git lfs fetch --all 2>&1; then
                echo -e "${YELLOW}WARNING${NC}: Failed to fetch some LFS objects, continuing..."
            fi
        fi
    else
        # Fetch all LFS objects
        if ! git lfs fetch --all 2>&1; then
            echo -e "${YELLOW}WARNING${NC}: Failed to fetch some LFS objects, continuing..."
        fi
    fi

    # Checkout LFS files
    echo -e "${BLUE}INFO${NC}: Checking out Git LFS files..."
    if ! git lfs checkout 2>&1; then
        echo -e "${YELLOW}WARNING${NC}: Failed to checkout some LFS files, continuing..."
    fi

    # Show current commit info
    local current_commit=$(git rev-parse HEAD 2>/dev/null)
    local commit_date_info=$(git log -1 --format='%ci' 2>/dev/null)
    echo -e "${GREEN}OK${NC}: Repository cloned/fetched successfully"
    echo -e "${BLUE}INFO${NC}: Repository directory: ${repo_dir}"
    echo -e "${BLUE}INFO${NC}: Current commit: ${current_commit}"
    if [ -n "$commit_date_info" ]; then
        echo -e "${BLUE}INFO${NC}: Commit date: ${commit_date_info}"
    fi
    return 0
}

# Download S3 bucket data
download_s3_data() {
    local endpoint="$1"
    local bucket="$2"
    local access_key="$3"
    local secret_key="$4"
    local region="$5"
    local work_dir="$6"
    local repo_dir="${7:-}"
    local commit_date="${8:-}"
    local download_dir="${work_dir}/s3-source"

    echo -e "${BLUE}INFO${NC}: Downloading S3 bucket data..."
    echo -e "${BLUE}INFO${NC}: Endpoint: ${endpoint}"
    echo -e "${BLUE}INFO${NC}: Bucket: ${bucket}"

    # Configure AWS CLI for source
    export AWS_ACCESS_KEY_ID="$access_key"
    export AWS_SECRET_ACCESS_KEY="$secret_key"
    export AWS_DEFAULT_REGION="$region"

    # Parse endpoint to determine if we need --endpoint-url
    local endpoint_url=""
    if [[ "$endpoint" =~ ^https?:// ]]; then
        endpoint_url="$endpoint"
    else
        endpoint_url="https://${endpoint}"
    fi

    # Create download directory
    mkdir -p "$download_dir"

    # If repo_dir is provided and commit_date is set, filter S3 objects by LFS pointers
    if [ -n "$repo_dir" ] && [ -d "$repo_dir" ] && [ -n "$commit_date" ]; then
        echo -e "${BLUE}INFO${NC}: Filtering S3 objects by commit date: ${commit_date}"

        # Get list of LFS objects referenced in the current commit
        local lfs_objects_file="${work_dir}/lfs-objects-list.txt"
        cd "$repo_dir" || return 1

        # Extract LFS object OIDs from tracked files
        echo -e "${BLUE}INFO${NC}: Extracting LFS object references from repository..."
        rm -f "$lfs_objects_file"

        # Method 1: Get OIDs from git lfs ls-files (shows OID for each tracked file)
        git lfs ls-files 2>/dev/null | awk '{print $2}' | grep -E '^[a-f0-9]{64}$' >> "$lfs_objects_file" || true

        # Method 2: Extract OIDs from LFS pointer files in working directory
        find . -type f ! -path './.git/*' 2>/dev/null | while read -r file; do
            # Check if file is an LFS pointer (starts with "version https://git-lfs.github.com/spec/v1")
            if head -1 "$file" 2>/dev/null | grep -q "version https://git-lfs.github.com/spec/v1"; then
                # Extract OID from pointer file
                local oid=$(grep "^oid sha256:" "$file" 2>/dev/null | sed 's/oid sha256://' | tr -d '[:space:]')
                if [ -n "$oid" ] && [ ${#oid} -eq 64 ]; then
                    echo "$oid" >> "$lfs_objects_file"
                fi
            fi
        done

        # Method 3: Extract OIDs from .git/lfs/objects directory structure
        if [ -d ".git/lfs/objects" ]; then
            find .git/lfs/objects -type f 2>/dev/null | while read -r obj_file; do
                # Git LFS stores objects as: .git/lfs/objects/prefix/subdir/oid
                local oid=$(basename "$obj_file")
                if [ ${#oid} -eq 64 ] && [[ "$oid" =~ ^[a-f0-9]{64}$ ]]; then
                    echo "$oid" >> "$lfs_objects_file"
                fi
            done
        fi

        # Method 4: Get OIDs from git lfs pointer files in .git directory
        if [ -d ".git/lfs" ]; then
            find .git/lfs -name "*.lfs" -type f 2>/dev/null | while read -r pointer_file; do
                local oid=$(grep "^oid sha256:" "$pointer_file" 2>/dev/null | sed 's/oid sha256://' | tr -d '[:space:]')
                if [ -n "$oid" ] && [ ${#oid} -eq 64 ]; then
                    echo "$oid" >> "$lfs_objects_file"
                fi
            done
        fi

        # Download only LFS objects that match the OIDs
        if [ -f "$lfs_objects_file" ] && [ -s "$lfs_objects_file" ]; then
            # Remove duplicates and sort
            sort -u "$lfs_objects_file" -o "$lfs_objects_file"
            local object_count=$(wc -l < "$lfs_objects_file")
            echo -e "${BLUE}INFO${NC}: Found ${object_count} unique LFS object references"
            echo -e "${BLUE}INFO${NC}: Downloading matching S3 objects..."

            local downloaded_count=0
            # Git LFS stores objects in S3 with OID-based paths
            # Format: bucket/oid_prefix/oid_suffix/oid
            while IFS= read -r lfs_oid; do
                if [ -n "$lfs_oid" ] && [ ${#lfs_oid} -ge 64 ]; then
                    # Git LFS OID format: first 2 chars as prefix, next 2 as subdirectory, full OID
                    local oid_prefix=$(echo "$lfs_oid" | cut -c1-2)
                    local oid_subdir=$(echo "$lfs_oid" | cut -c3-4)
                    local s3_key="${oid_prefix}/${oid_subdir}/${lfs_oid}"

                    # Try to download the object
                    local dest_path="${download_dir}/${s3_key}"
                    mkdir -p "$(dirname "$dest_path")"

                    if aws s3 cp "s3://${bucket}/${s3_key}" "$dest_path" \
                        --endpoint-url "$endpoint_url" \
                        --no-verify-ssl 2>/dev/null; then
                        downloaded_count=$((downloaded_count + 1))
                        if [ $((downloaded_count % 10)) -eq 0 ]; then
                            echo -e "${BLUE}INFO${NC}: Downloaded ${downloaded_count}/${object_count} LFS objects..."
                        fi
                    fi
                fi
            done < "$lfs_objects_file"

            echo -e "${GREEN}OK${NC}: Downloaded ${downloaded_count} LFS objects from S3"
        else
            echo -e "${YELLOW}WARNING${NC}: No LFS objects found in repository, downloading all S3 objects..."
            # Fall back to syncing all objects
            aws s3 sync "s3://${bucket}/" "$download_dir/" \
                --endpoint-url "$endpoint_url" \
                --no-verify-ssl 2>&1
        fi
    else
        # Sync all S3 bucket to local directory
        echo -e "${BLUE}INFO${NC}: Syncing all S3 bucket data to local directory..."
        if aws s3 sync "s3://${bucket}/" "$download_dir/" \
            --endpoint-url "$endpoint_url" \
            --no-verify-ssl 2>&1; then
            echo -e "${GREEN}OK${NC}: S3 bucket data downloaded successfully"
            echo -e "${BLUE}INFO${NC}: Downloaded to: ${download_dir}"

            # Count files
            local file_count=$(find "$download_dir" -type f | wc -l)
            echo -e "${BLUE}INFO${NC}: Downloaded ${file_count} files"
            return 0
        else
            echo -e "${RED}ERROR${NC}: Failed to download S3 bucket data"
            return 1
        fi
    fi

    # Count downloaded files
    local file_count=$(find "$download_dir" -type f 2>/dev/null | wc -l)
    if [ "$file_count" -gt 0 ]; then
        echo -e "${GREEN}OK${NC}: S3 bucket data downloaded successfully"
        echo -e "${BLUE}INFO${NC}: Downloaded to: ${download_dir}"
        echo -e "${BLUE}INFO${NC}: Downloaded ${file_count} files"
        return 0
    else
        echo -e "${YELLOW}WARNING${NC}: No files downloaded from S3 bucket"
        return 0
    fi
}

# Upload S3 bucket data
upload_s3_data() {
    local endpoint="$1"
    local bucket="$2"
    local access_key="$3"
    local secret_key="$4"
    local region="$5"
    local source_dir="$6"

    echo -e "${BLUE}INFO${NC}: Uploading S3 bucket data..."
    echo -e "${BLUE}INFO${NC}: Endpoint: ${endpoint}"
    echo -e "${BLUE}INFO${NC}: Bucket: ${bucket}"

    # Configure AWS CLI for destination
    export AWS_ACCESS_KEY_ID="$access_key"
    export AWS_SECRET_ACCESS_KEY="$secret_key"
    export AWS_DEFAULT_REGION="$region"

    # Parse endpoint to determine if we need --endpoint-url
    local endpoint_url=""
    if [[ "$endpoint" =~ ^https?:// ]]; then
        endpoint_url="$endpoint"
    else
        endpoint_url="https://${endpoint}"
    fi

    # Check if bucket exists, create if not
    echo -e "${BLUE}INFO${NC}: Checking if bucket exists..."
    if ! aws s3 ls "s3://${bucket}" --endpoint-url "$endpoint_url" --no-verify-ssl >/dev/null 2>&1; then
        echo -e "${BLUE}INFO${NC}: Bucket does not exist, creating..."
        if ! aws s3 mb "s3://${bucket}" --endpoint-url "$endpoint_url" --no-verify-ssl 2>&1; then
            echo -e "${RED}ERROR${NC}: Failed to create bucket"
            return 1
        fi
    fi

    # Sync local directory to S3 bucket
    echo -e "${BLUE}INFO${NC}: Syncing local directory to S3 bucket..."
    if aws s3 sync "$source_dir/" "s3://${bucket}/" \
        --endpoint-url "$endpoint_url" \
        --no-verify-ssl 2>&1; then
        echo -e "${GREEN}OK${NC}: S3 bucket data uploaded successfully"

        # Count files
        local file_count=$(find "$source_dir" -type f | wc -l)
        echo -e "${BLUE}INFO${NC}: Uploaded ${file_count} files"
        return 0
    else
        echo -e "${RED}ERROR${NC}: Failed to upload S3 bucket data"
        return 1
    fi
}

# Push to destination repository
push_to_dest() {
    local repo_url="$1"
    local branch="$2"
    local work_dir="$3"
    local repo_name=$(basename "$repo_url" .git)
    local repo_dir="${work_dir}/${repo_name}"

    echo -e "${BLUE}INFO${NC}: Pushing to destination repository: ${repo_url}"

    if [ ! -d "$repo_dir" ]; then
        echo -e "${RED}ERROR${NC}: Repository directory not found: ${repo_dir}"
        return 1
    fi

    cd "$repo_dir" || return 1

    # Check if remote exists, add if not
    if ! git remote get-url dest >/dev/null 2>&1; then
        echo -e "${BLUE}INFO${NC}: Adding destination remote..."
        git remote add dest "$repo_url" 2>&1
    else
        echo -e "${BLUE}INFO${NC}: Updating destination remote URL..."
        git remote set-url dest "$repo_url" 2>&1
    fi

    # Push to destination
    echo -e "${BLUE}INFO${NC}: Pushing branch ${branch} to destination..."

    # Set SSL verification skip for git-lfs
    export GIT_SSL_NO_VERIFY=1
    export GIT_LFS_SKIP_SSL_VERIFY=1

    if git push dest "${branch}:${branch}" --force 2>&1; then
        echo -e "${GREEN}OK${NC}: Successfully pushed to destination repository"

        # Push LFS objects
        echo -e "${BLUE}INFO${NC}: Pushing Git LFS objects..."
        if git lfs push dest --all 2>&1; then
            echo -e "${GREEN}OK${NC}: Successfully pushed LFS objects"
        else
            echo -e "${YELLOW}WARNING${NC}: Failed to push some LFS objects"
        fi

        return 0
    else
        echo -e "${RED}ERROR${NC}: Failed to push to destination repository"
        return 1
    fi
}

# Perform full migration
perform_migration() {
    echo -e "${BLUE}INFO${NC}: Starting Git LFS migration..."
    echo ""

    # Load configuration
    load_config

    # Check dependencies
    if ! check_dependencies; then
        return 1
    fi

    # Validate configuration
    if [ -z "$SOURCE_GIT_URL" ] || [ -z "$DEST_GIT_URL" ]; then
        echo -e "${RED}ERROR${NC}: Source and destination Git URLs must be configured"
        echo -e "${BLUE}INFO${NC}: Run '$0 config' to configure migration"
        return 1
    fi

    # Create work directory
    WORK_DIR="${WORK_DIR:-/tmp/git-lfs-migrate}"
    mkdir -p "$WORK_DIR"

    # Step 1: Clone or fetch source repository
    echo ""
    echo -e "${BLUE}=== Step 1: Clone/Fetch Source Repository ===${NC}"
    local repo_name=$(basename "$SOURCE_GIT_URL" .git)
    local repo_dir="${WORK_DIR}/${repo_name}"

    if ! clone_or_fetch_repo \
        "$SOURCE_GIT_URL" \
        "${SOURCE_GIT_BRANCH:-master}" \
        "$WORK_DIR" \
        "${SOURCE_COMMIT_HASH:-}" \
        "${SOURCE_COMMIT_DATE:-}"; then
        echo -e "${RED}ERROR${NC}: Failed to clone/fetch source repository"
        return 1
    fi

    # Step 2: Download S3 bucket data
    if [ "${SKIP_S3_SYNC:-false}" != "true" ]; then
        echo ""
        echo -e "${BLUE}=== Step 2: Download Source S3 Bucket Data ===${NC}"
        if [ -n "$SOURCE_S3_ENDPOINT" ] && [ -n "$SOURCE_S3_BUCKET" ]; then
            if ! download_s3_data \
                "$SOURCE_S3_ENDPOINT" \
                "$SOURCE_S3_BUCKET" \
                "$SOURCE_S3_ACCESS_KEY" \
                "$SOURCE_S3_SECRET_KEY" \
                "${SOURCE_S3_REGION:-us-east-1}" \
                "$WORK_DIR" \
                "$repo_dir" \
                "${SOURCE_COMMIT_DATE:-}"; then
                echo -e "${YELLOW}WARNING${NC}: Failed to download S3 bucket data, continuing..."
            fi
        else
            echo -e "${YELLOW}WARNING${NC}: S3 configuration not provided, skipping S3 download"
        fi
    else
        echo -e "${BLUE}INFO${NC}: Skipping S3 download (SKIP_S3_SYNC=true)"
    fi

    # Step 3: Upload S3 bucket data to destination
    if [ "${SKIP_S3_SYNC:-false}" != "true" ]; then
        echo ""
        echo -e "${BLUE}=== Step 3: Upload to Destination S3 Bucket ===${NC}"
        if [ -n "$DEST_S3_ENDPOINT" ] && [ -n "$DEST_S3_BUCKET" ]; then
            local download_dir="${WORK_DIR}/s3-source"
            if [ -d "$download_dir" ]; then
                if ! upload_s3_data \
                    "$DEST_S3_ENDPOINT" \
                    "$DEST_S3_BUCKET" \
                    "$DEST_S3_ACCESS_KEY" \
                    "$DEST_S3_SECRET_KEY" \
                    "${DEST_S3_REGION:-us-east-1}" \
                    "$download_dir"; then
                echo -e "${YELLOW}WARNING${NC}: Failed to upload S3 bucket data, continuing..."
            fi
            else
                echo -e "${YELLOW}WARNING${NC}: Source S3 data directory not found, skipping upload"
            fi
        else
            echo -e "${YELLOW}WARNING${NC}: Destination S3 configuration not provided, skipping S3 upload"
        fi
    else
        echo -e "${BLUE}INFO${NC}: Skipping S3 upload (SKIP_S3_SYNC=true)"
    fi

    # Step 4: Push to destination repository
    if [ "${SKIP_GIT_PUSH:-false}" != "true" ]; then
        echo ""
        echo -e "${BLUE}=== Step 4: Push to Destination Repository ===${NC}"
        if ! push_to_dest "$DEST_GIT_URL" "${DEST_GIT_BRANCH:-master}" "$WORK_DIR"; then
            echo -e "${RED}ERROR${NC}: Failed to push to destination repository"
            return 1
        fi
    else
        echo -e "${BLUE}INFO${NC}: Skipping Git push (SKIP_GIT_PUSH=true)"
    fi

    echo ""
    echo -e "${GREEN}=== Migration Completed Successfully ===${NC}"
    echo -e "${BLUE}INFO${NC}: Work directory: ${WORK_DIR}"
    return 0
}

# Show script version
show_version() {
    echo "migrate.sh ${SCRIPT_VERSION}"
}

# Show help information
show_help() {
    cat << EOF
Git LFS Repository Migration Script

Usage: $0 [command] [options]

Commands:
    config      Configure source and destination repositories and S3 buckets
    migrate     Perform full migration (clone/fetch, download S3, upload S3, push)
    clone       Clone or fetch source repository only
    fetch-s3    Download S3 bucket data from source only
    upload-s3   Upload S3 bucket data to destination only
    push        Push repository to destination only
    check       Check dependencies and configuration
    version     Show version information
    help        Show this help message

Options:
    --skip-s3-sync    Skip S3 bucket synchronization
    --skip-git-push   Skip Git repository push

Commit Date Support:
    You can specify a specific commit date or hash to clone/fetch LFS objects
    from a specific point in time. This will:
    - Checkout the repository to the specified commit/date
    - Only download S3 bucket data for LFS objects referenced by that commit

    Configure via 'config' command or set in config file:
    - SOURCE_COMMIT_HASH: Specific commit hash (e.g., abc123def)
    - SOURCE_COMMIT_DATE: Date string (e.g., '2024-01-01' or '2024-01-01 12:00:00')

Examples:
    # Configure migration settings
    $0 config

    # Perform full migration
    $0 migrate

    # Clone source repository only
    $0 clone

    # Download S3 data only
    $0 fetch-s3

    # Upload S3 data only
    $0 upload-s3

    # Push to destination only
    $0 push

    # Check configuration
    $0 check

Configuration:
    Configuration is saved to: ${CONFIG_FILE}
    You can edit this file directly or run '$0 config' to reconfigure.

Environment Variables:
    GIT_SSL_NO_VERIFY=1          Skip SSL verification for Git operations
    GIT_LFS_SKIP_SSL_VERIFY=1    Skip SSL verification for Git LFS operations
    AWS_ACCESS_KEY_ID            AWS access key (if not in config)
    AWS_SECRET_ACCESS_KEY        AWS secret key (if not in config)

EOF
}

# Main program
main() {
    case "$1" in
        config)
            configure_migration
            ;;
        migrate)
            perform_migration
            ;;
        clone)
            load_config
            if ! check_dependencies; then
                exit 1
            fi
            WORK_DIR="${WORK_DIR:-/tmp/git-lfs-migrate}"
            clone_or_fetch_repo \
                "$SOURCE_GIT_URL" \
                "${SOURCE_GIT_BRANCH:-master}" \
                "$WORK_DIR" \
                "${SOURCE_COMMIT_HASH:-}" \
                "${SOURCE_COMMIT_DATE:-}"
            ;;
        fetch-s3)
            load_config
            if ! check_dependencies; then
                exit 1
            fi
            WORK_DIR="${WORK_DIR:-/tmp/git-lfs-migrate}"
            local repo_name=$(basename "$SOURCE_GIT_URL" .git)
            local repo_dir="${WORK_DIR}/${repo_name}"
            download_s3_data \
                "$SOURCE_S3_ENDPOINT" \
                "$SOURCE_S3_BUCKET" \
                "$SOURCE_S3_ACCESS_KEY" \
                "$SOURCE_S3_SECRET_KEY" \
                "${SOURCE_S3_REGION:-us-east-1}" \
                "$WORK_DIR" \
                "$repo_dir" \
                "${SOURCE_COMMIT_DATE:-}"
            ;;
        upload-s3)
            load_config
            if ! check_dependencies; then
                exit 1
            fi
            WORK_DIR="${WORK_DIR:-/tmp/git-lfs-migrate}"
            download_dir="${WORK_DIR}/s3-source"
            if [ ! -d "$download_dir" ]; then
                echo -e "${RED}ERROR${NC}: Source S3 data directory not found: ${download_dir}"
                echo -e "${BLUE}INFO${NC}: Run '$0 fetch-s3' first to download S3 data"
                exit 1
            fi
            upload_s3_data \
                "$DEST_S3_ENDPOINT" \
                "$DEST_S3_BUCKET" \
                "$DEST_S3_ACCESS_KEY" \
                "$DEST_S3_SECRET_KEY" \
                "${DEST_S3_REGION:-us-east-1}" \
                "$download_dir"
            ;;
        push)
            load_config
            if ! check_dependencies; then
                exit 1
            fi
            WORK_DIR="${WORK_DIR:-/tmp/git-lfs-migrate}"
            push_to_dest "$DEST_GIT_URL" "${DEST_GIT_BRANCH:-master}" "$WORK_DIR"
            ;;
        check)
            check_dependencies
            load_config
            echo ""
            echo -e "${BLUE}INFO${NC}: Current configuration:"
            echo -e "  Source Git URL: ${SOURCE_GIT_URL:-not set}"
            echo -e "  Source Git Branch: ${SOURCE_GIT_BRANCH:-master}"
            echo -e "  Source Commit Hash: ${SOURCE_COMMIT_HASH:-not set}"
            echo -e "  Source Commit Date: ${SOURCE_COMMIT_DATE:-not set}"
            echo -e "  Source S3 Endpoint: ${SOURCE_S3_ENDPOINT:-not set}"
            echo -e "  Source S3 Bucket: ${SOURCE_S3_BUCKET:-not set}"
            echo -e "  Destination Git URL: ${DEST_GIT_URL:-not set}"
            echo -e "  Destination S3 Endpoint: ${DEST_S3_ENDPOINT:-not set}"
            echo -e "  Destination S3 Bucket: ${DEST_S3_BUCKET:-not set}"
            echo -e "  Work Directory: ${WORK_DIR:-/tmp/git-lfs-migrate}"
            ;;
        version|--version|-v)
            show_version
            ;;
        help|--help|-h)
            show_help
            ;;
        "")
            show_help
            ;;
        *)
            echo -e "${RED}ERROR${NC}: Unknown command: $1"
            echo -e "${BLUE}INFO${NC}: Use '$0 help' for help"
            exit 1
            ;;
    esac
}

main "$@"
