#!/bin/bash
set -e # Stop script immediately if any command fails

# -------------------------------------------------------------
# Dependency Check
# -------------------------------------------------------------
REQUIRED_TOOLS=("curl" "unzip")
MISSING_TOOLS=()

for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        MISSING_TOOLS+=("$tool")
    fi
done

if [ ${#MISSING_TOOLS[@]} -ne 0 ]; then
    echo "========================================================"
    echo "Error: Missing required tool(s): ${MISSING_TOOLS[*]}"
    echo "========================================================"
    echo "Please install the missing package(s) using your package manager:"
    echo ""
    echo "  • Ubuntu / Debian / Mint:"
    echo "      sudo apt update && sudo apt install -y ${MISSING_TOOLS[*]}"
    echo ""
    echo "  • Fedora / RHEL:"
    echo "      sudo dnf install -y ${MISSING_TOOLS[*]}"
    echo ""
    echo "  • Arch Linux / Manjaro:"
    echo "      sudo pacman -S --needed ${MISSING_TOOLS[*]}"
    echo "========================================================"
    exit 1
fi

# -------------------------------------------------------------
# Installation / Update Logic
# -------------------------------------------------------------
REPO="Gollum00002/Hordr-Media-Library-App"
FILE_NAME="Hordr-Linux.zip"
DOWNLOAD_URL="https://github.com/$REPO/releases/latest/download/$FILE_NAME"

echo "==> Downloading latest release from GitHub..."
# --fail makes curl exit with an error code if the release URL returns a 404
curl -L --fail -o "$FILE_NAME" "$DOWNLOAD_URL"

echo "==> Extracting files..."
# -o overwrites existing files without asking
unzip -o "$FILE_NAME"

echo "==> Cleaning up installer..."
# Remove the zip file to free up disk space
rm -f "$FILE_NAME"

echo "==> Successfully installed/updated!"