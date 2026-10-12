#!/bin/bash
set -e # Stop script immediately if any command fails

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
# Remove the 1 GB zip file to free up disk space
rm -f "$FILE_NAME"

echo "==> Successfully installed/updated!"