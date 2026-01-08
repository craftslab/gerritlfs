#!/bin/bash

# Script version
SCRIPT_VERSION="1.0.0"

# Terminal colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'  # No Color

# Artifactory base URL and credentials
ART_BASE="https://artifactory.example.com/artifactory"
ART_USER="your_username"
ART_PASS="your_password"

# S3 host and IP defaults
S3_HOST_DEFAULT="s3.example.com"
S3_IP_DEFAULT="127.0.0.1"

# Check Git LFS
check_git_lfs() {
    # Check if git-lfs is installed
    if ! command -v git-lfs &> /dev/null; then
        echo -e "${RED}ERROR${NC}: git-lfs is not installed"
        echo -e "${BLUE}INFO${NC}: Run '$0 config' to install git-lfs"
        echo ""
        return 1
    fi

    echo -e "${BLUE}INFO${NC}: git-lfs is installed ($(git lfs version))"
    echo ""
}

# Configure Git LFS
config_git_lfs() {
    # Check if git-lfs is already installed
    if command -v git-lfs &> /dev/null; then
        echo -e "${BLUE}INFO${NC}: git-lfs is already installed ($(git lfs version))"
        read -p "Reinstall? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi

    echo -e "Select operation:"
    echo -e "   1. Install with apt (Recommended)"
    echo -e "   2. Download from Artifactory"
    read -p "Enter selection (1-2): " -n 1 -r selection
    echo

    case "$selection" in
        1)
            echo -e "${BLUE}INFO${NC}: Installing git-lfs via apt..."
            sudo apt-get update -qq
            sudo apt-get install -y -qq git-lfs
            if [ $? -eq 0 ]; then
                git lfs install >/dev/null 2>&1
                echo -e "${GREEN}DONE${NC}: git-lfs installed successfully"
                echo ""
                return 0
            else
                echo -e "${RED}ERROR${NC}: Failed to install git-lfs"
                return 1
            fi
            ;;
        2)
            echo -e "${BLUE}INFO${NC}: Installing git-lfs from Artifactory..."
            TAG=3.7.1
            TEMP_DIR="/tmp/git-lfs-install-$$"
            mkdir -p "$TEMP_DIR"
            cd "$TEMP_DIR" || exit 1

            if curl -s -k -u"${ART_USER}:${ART_PASS}" -LO "${ART_BASE}/git-lfs/git-lfs-linux-amd64-v$TAG.tar.gz" 2>/dev/null; then
                tar zxf "git-lfs-linux-amd64-v$TAG.tar.gz" >/dev/null 2>&1
                cd "git-lfs-$TAG" || exit 1
                sudo ./install.sh >/dev/null 2>&1
                if [ $? -eq 0 ]; then
                    git lfs install >/dev/null 2>&1
                    echo -e "${GREEN}DONE${NC}: git-lfs installed successfully"
                    echo ""
                else
                    echo -e "${RED}ERROR${NC}: Failed to install git-lfs"
                    cd /
                    rm -rf "$TEMP_DIR"
                    return 1
                fi
            else
                echo -e "${RED}ERROR${NC}: Failed to download git-lfs"
                cd /
                rm -rf "$TEMP_DIR"
                return 1
            fi

            cd /
            rm -rf "$TEMP_DIR"
            echo ""
            return 0
            ;;
        *)
            echo -e "${RED}ERROR${NC}: Invalid selection"
            return 1
            ;;
    esac
}

# Clean Git LFS
clean_git_lfs() {
    # Check if git-lfs is installed
    if ! command -v git-lfs &> /dev/null; then
        echo -e "${BLUE}INFO${NC}: git-lfs is not installed"
        echo ""
        return 1
    fi

    echo -e "Select clean operation:"
    echo -e "   1. Clean git-lfs cache"
    echo -e "   2. Uninstall git-lfs"
    read -p "Enter selection (1-2): " -n 1 -r selection
    echo

    case "$selection" in
        1)
            echo -e "${BLUE}INFO${NC}: Cleaning git-lfs cache..."
            git lfs prune >/dev/null 2>&1
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}DONE${NC}: git-lfs cache cleaned successfully"
                echo ""
            else
                echo -e "${RED}ERROR${NC}: Failed to clean git-lfs cache"
                echo ""
                return 1
            fi
            ;;
        2)
            echo -e "${BLUE}INFO${NC}: Uninstalling git-lfs..."
            read -p "Are you sure you want to uninstall git-lfs? (y/N): " -n 1 -r confirm
            echo
            if [[ ! $confirm =~ ^[Yy]$ ]]; then
                return 0
            fi

            git lfs uninstall >/dev/null 2>&1
            sudo apt-get remove -y -qq git-lfs >/dev/null 2>&1
            apt_status=$?

            # Remove manual install binary if still present
            if command -v git-lfs &> /dev/null; then
                bin_path=$(command -v git-lfs)
                echo -e "${BLUE}INFO${NC}: Removing git-lfs binary at ${bin_path}"
                sudo rm -f "$bin_path"
            fi

            if command -v git-lfs &> /dev/null; then
                echo -e "${RED}ERROR${NC}: git-lfs is still present after uninstall"
                echo ""
                return 1
            fi

            if [ $apt_status -eq 0 ]; then
                echo -e "${GREEN}DONE${NC}: git-lfs uninstalled successfully"
                echo ""
            fi
            ;;
        *)
            echo -e "${RED}ERROR${NC}: Invalid selection"
            echo ""
            return 1
            ;;
    esac
}

# Check S3 certificate status
check_s3_certificate() {
    local S3_SERVER_URL
    local cert_path

    read -p "Enter S3 server URL to check (default: ${S3_HOST_DEFAULT}): " S3_SERVER_URL
    if [ -z "$S3_SERVER_URL" ]; then
        S3_SERVER_URL="$S3_HOST_DEFAULT"
    fi

    cert_path="/usr/local/share/ca-certificates/${S3_SERVER_URL}.crt"

    if [ -f "$cert_path" ]; then
        echo -e "${BLUE}INFO${NC}: Certificate found at ${cert_path}"
        echo ""
        return 0
    else
        echo -e "${RED}ERROR${NC}: Certificate not found at ${cert_path}"
        echo -e "${BLUE}INFO${NC}: Run '$0 config' to install S3 certificate"
        echo ""
        return 1
    fi
}

# Configure S3 certificate into system trust store
config_s3_certificate() {
    local S3_SERVER_URL
    local TEMP_DIR

    read -p "Enter S3 server URL (default: ${S3_HOST_DEFAULT}): " S3_SERVER_URL
    if [ -z "$S3_SERVER_URL" ]; then
        S3_SERVER_URL="$S3_HOST_DEFAULT"
    fi

    echo -e "${BLUE}INFO${NC}: Downloading certificate for ${S3_SERVER_URL}"
    TEMP_DIR="/tmp/s3-cert-$$"
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR" || { echo -e "${RED}ERROR${NC}: Cannot access temp dir"; return 1; }

    if curl -s -k -u"${ART_USER}:${ART_PASS}" -L \
        "${ART_BASE}/rustfs/${S3_SERVER_URL}.crt" \
        -o "${S3_SERVER_URL}.crt" 2>/dev/null; then
        :
    else
        echo -e "${RED}ERROR${NC}: Failed to download certificate"
        cd /
        rm -rf "$TEMP_DIR"
        return 1
    fi

    echo -e "${BLUE}INFO${NC}: Installing certificate to /usr/local/share/ca-certificates"
    sudo mv "${S3_SERVER_URL}.crt" \
        "/usr/local/share/ca-certificates/${S3_SERVER_URL}.crt" || { echo -e "${RED}ERROR${NC}: Move failed"; cd /; rm -rf "$TEMP_DIR"; return 1; }

    echo -e "${BLUE}INFO${NC}: Updating CA certificates"
    if sudo update-ca-certificates >/dev/null 2>&1; then
        echo -e "${GREEN}DONE${NC}: Certificate installed and trust store updated"
        echo ""
    else
        echo -e "${RED}ERROR${NC}: Failed to update CA certificates"
        cd /
        rm -rf "$TEMP_DIR"
        return 1
    fi

    cd /
    rm -rf "$TEMP_DIR"
}

# Clean S3 certificate from system trust store
clean_s3_certificate() {
    local S3_SERVER_URL
    local cert_path

    read -p "Enter S3 server URL to clean (default: ${S3_HOST_DEFAULT}): " S3_SERVER_URL
    if [ -z "$S3_SERVER_URL" ]; then
        S3_SERVER_URL="$S3_HOST_DEFAULT"
    fi

    cert_path="/usr/local/share/ca-certificates/${S3_SERVER_URL}.crt"

    if [ ! -f "$cert_path" ]; then
        echo -e "${BLUE}INFO${NC}: Certificate not found at ${cert_path}, nothing to clean"
        echo ""
        return 0
    fi

    echo -e "${BLUE}INFO${NC}: Removing certificate ${cert_path}"
    sudo rm -f "$cert_path" || { echo -e "${RED}ERROR${NC}: Failed to remove certificate"; echo ""; return 1; }

    echo -e "${BLUE}INFO${NC}: Updating CA certificates"
    if sudo update-ca-certificates >/dev/null 2>&1; then
        echo -e "${GREEN}DONE${NC}: Certificate removed and trust store updated"
        echo ""
        return 0
    else
        echo -e "${RED}ERROR${NC}: Failed to update CA certificates"
        echo ""
        return 1
    fi
}

# Check S3 host mapping status
check_s3_host() {
    local S3_SERVER_URL

    read -p "Enter S3 server URL to check (default: ${S3_HOST_DEFAULT}): " S3_SERVER_URL
    if [ -z "$S3_SERVER_URL" ]; then
        S3_SERVER_URL="$S3_HOST_DEFAULT"
    fi

    # Check if mapping exists
    if grep -q "$S3_SERVER_URL" /etc/hosts 2>/dev/null; then
        echo -e "${BLUE}INFO${NC}: Mapping for ${S3_SERVER_URL} found in /etc/hosts"
        echo ""
        return 0
    else
        echo -e "${RED}ERROR${NC}: Mapping for ${S3_SERVER_URL} not found in /etc/hosts"
        echo -e "${BLUE}INFO${NC}: Run '$0 config' to add S3 host mapping"
        echo ""
        return 1
    fi
}

# Configure S3 host mapping in /etc/hosts
config_s3_host() {
    local S3_SERVER_IP
    local S3_SERVER_URL

    read -p "Enter S3 server IP (default: ${S3_IP_DEFAULT}): " S3_SERVER_IP
    if [ -z "$S3_SERVER_IP" ]; then
        S3_SERVER_IP="$S3_IP_DEFAULT"
    fi

    read -p "Enter S3 server URL (default: ${S3_HOST_DEFAULT}): " S3_SERVER_URL
    if [ -z "$S3_SERVER_URL" ]; then
        S3_SERVER_URL="$S3_HOST_DEFAULT"
    fi

    # Check if mapping already exists
    if grep -q "$S3_SERVER_URL" /etc/hosts 2>/dev/null; then
        echo -e "${BLUE}INFO${NC}: Mapping for ${S3_SERVER_URL} already exists in /etc/hosts"
        read -p "Update mapping? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 0
        fi
        # Remove old mapping
        sudo sed -i.bak "/.*${S3_SERVER_URL}.*/d" /etc/hosts
    fi

    echo -e "${BLUE}INFO${NC}: Adding mapping to /etc/hosts"
    if echo "$S3_SERVER_IP  $S3_SERVER_URL s3-us-east-1.amazonaws.com" | sudo tee -a /etc/hosts >/dev/null; then
        echo -e "${GREEN}DONE${NC}: Host mapping added successfully"
        echo ""
        return 0
    else
        echo -e "${RED}ERROR${NC}: Failed to add host mapping"
        return 1
    fi
}

# Clean S3 host mapping from /etc/hosts
clean_s3_host() {
    local S3_SERVER_URL

    read -p "Enter S3 server URL to clean (default: ${S3_HOST_DEFAULT}): " S3_SERVER_URL
    if [ -z "$S3_SERVER_URL" ]; then
        S3_SERVER_URL="$S3_HOST_DEFAULT"
    fi

    # Check if mapping exists
    if ! grep -q "$S3_SERVER_URL" /etc/hosts 2>/dev/null; then
        echo -e "${BLUE}INFO${NC}: Mapping for ${S3_SERVER_URL} not found in /etc/hosts, nothing to clean"
        echo ""
        return 0
    fi

    echo -e "${BLUE}INFO${NC}: Removing mapping for ${S3_SERVER_URL} from /etc/hosts"
    sudo sed -i.bak "/.*${S3_SERVER_URL}.*/d" /etc/hosts

    # Verify removal
    if grep -q "$S3_SERVER_URL" /etc/hosts 2>/dev/null; then
        echo -e "${RED}ERROR${NC}: Failed to remove mapping from /etc/hosts"
        echo ""
        return 1
    else
        echo -e "${GREEN}DONE${NC}: Host mapping removed successfully"
        echo ""
        return 0
    fi
}

# Check git aliases for LFS
check_git_alias() {
    echo -e "${BLUE}INFO${NC}: Checking git aliases..."

    local aliases=("push-lfs" "clone-lfs" "fetch-lfs" "checkout-lfs" "pull-lfs")
    local all_found=true

    for alias_name in "${aliases[@]}"; do
        if git config --global --get alias."${alias_name}" >/dev/null 2>&1; then
            local alias_value
            alias_value=$(git config --global --get alias."${alias_name}")
            echo -e "   ${alias_name}: ${alias_value}"
        else
            echo -e "   ${alias_name}: NOT FOUND"
            all_found=false
        fi
    done

    # Check credential helper
    if git config --global --get credential.helper >/dev/null 2>&1; then
        local cred_helper
        cred_helper=$(git config --global --get credential.helper)
        echo -e "   credential.helper: ${cred_helper}"
    else
        echo -e "   credential.helper: NOT FOUND"
    fi

    if [ "$all_found" = true ]; then
        return 0
    else
        echo -e "${BLUE}INFO${NC}: Run '$0 config' to configure git aliases"
        return 1
    fi
}

# Configure git aliases for LFS
config_git_alias() {
    echo -e "${BLUE}INFO${NC}: Configuring git aliases..."

    # Set git aliases with SSL verification disabled
    git config --global alias.push-lfs '!GIT_SSL_NO_VERIFY=1 GIT_LFS_SKIP_SSL_VERIFY=1 git push'
    git config --global alias.clone-lfs '!GIT_SSL_NO_VERIFY=1 GIT_LFS_SKIP_SSL_VERIFY=1 git clone'
    git config --global alias.fetch-lfs '!GIT_SSL_NO_VERIFY=1 GIT_LFS_SKIP_SSL_VERIFY=1 git lfs fetch'
    git config --global alias.checkout-lfs '!GIT_SSL_NO_VERIFY=1 GIT_LFS_SKIP_SSL_VERIFY=1 git lfs checkout'
    git config --global alias.pull-lfs '!GIT_SSL_NO_VERIFY=1 GIT_LFS_SKIP_SSL_VERIFY=1 git lfs pull'

    # Set up credential helper
    git config --global credential.helper store

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}DONE${NC}: Git aliases configured successfully"
        echo ""
        return 0
    else
        echo -e "${RED}ERROR${NC}: Failed to configure git aliases"
        return 1
    fi
}

# Clean git aliases for LFS
clean_git_alias() {
    echo -e "${BLUE}INFO${NC}: Cleaning git aliases..."

    # Remove git aliases
    git config --global --unset alias.push-lfs 2>/dev/null
    git config --global --unset alias.clone-lfs 2>/dev/null
    git config --global --unset alias.fetch-lfs 2>/dev/null
    git config --global --unset alias.checkout-lfs 2>/dev/null
    git config --global --unset alias.pull-lfs 2>/dev/null

    echo -e "${GREEN}DONE${NC}: Git aliases cleaned successfully"
    echo ""
    return 0
}

# Show script version
show_version() {
    echo "git-lfs.sh ${SCRIPT_VERSION}"
}

# Show help information
show_help() {
    cat << EOF
Git LFS Setup Script

Usage: $0 [options]

Options:
    check    Check Git LFS
    config   Configure Git LFS
    clean    Clean Git LFS
    version  Show version information
    help     Show help information

Examples:
    $0 check    Check Git LFS
    $0 config   Configure Git LFS
    $0 clean    Clean Git LFS
    $0 version  Show version
    $0 help     Show this help message
EOF
}

# Main program
main() {
    case "$1" in
        check)
            check_git_lfs
            check_s3_certificate
            check_s3_host
            check_git_alias
            ;;
        config)
            config_git_lfs
            if [ $? -eq 0 ]; then
                config_s3_certificate
                if [ $? -eq 0 ]; then
                    config_s3_host
                    if [ $? -eq 0 ]; then
                        config_git_alias
                        if [ $? -ne 0 ]; then
                            echo -e "${RED}ERROR${NC}: Git alias configuration failed"
                            exit 1
                        fi
                    else
                        echo -e "${RED}ERROR${NC}: S3 host configuration failed"
                        exit 1
                    fi
                else
                    echo -e "${RED}ERROR${NC}: S3 certificate configuration failed"
                    exit 1
                fi
            else
                echo -e "${RED}ERROR${NC}: git-lfs configuration failed"
                exit 1
            fi
            ;;
        clean)
            clean_git_alias
            clean_s3_host
            clean_s3_certificate
            clean_git_lfs
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
            echo -e "${RED}ERROR${NC}: Unknown option: $1"
            echo -e "${BLUE}INFO${NC}: Use '$0 help' for help"
            exit 1
            ;;
    esac
}

main "$@"
