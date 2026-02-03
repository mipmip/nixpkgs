#!/usr/bin/env bash
set -euo pipefail

# Script to update npmDepsHash in package.nix using prefetch-npm-deps
# This script fetches the source, applies patches, and computes the correct hash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_FILE="$SCRIPT_DIR/package.nix"
TEMP_DIR=$(mktemp -d)

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

echo "Updating npmDepsHash in $PACKAGE_FILE"

# Extract version from package.nix
VERSION=$(grep -oP 'version = "\K[^"]+' "$PACKAGE_FILE")
echo "Version: $VERSION"

# Fetch the source using nix-prefetch-url or clone from GitHub
echo "Fetching source..."
cd "$TEMP_DIR"
nix run nixpkgs#git -- clone https://github.com/quiqr/quiqr-desktop.git source

cd source
nix run nixpkgs#git -- checkout tags/v$VERSION

# Apply patches if they exist
echo "Applying patches..."
if [ -f "$SCRIPT_DIR/package-lock.json.patch" ]; then
    patch -p1 < "$SCRIPT_DIR/package-lock.json.patch" || echo "Warning: Could not apply package-lock.json.patch"
fi
if [ -f "$SCRIPT_DIR/package.json.patch" ]; then
    patch -p1 < "$SCRIPT_DIR/package.json.patch" || echo "Warning: Could not apply package.json.patch"
fi

# Check if package-lock.json exists
if [ ! -f "package-lock.json" ]; then
    echo "Error: package-lock.json not found after applying patches"
    exit 1
fi

# Calculate hash using prefetch-npm-deps
echo "Computing npm dependencies hash..."
CORRECT_HASH=$(nix-shell -p prefetch-npm-deps --run "prefetch-npm-deps package-lock.json")

if [ -z "$CORRECT_HASH" ]; then
    echo "Error: Could not compute hash"
    exit 1
fi

echo "Found correct hash: $CORRECT_HASH"

# Update package.nix with the correct hash
sed -i "s|npmDepsHash = \"[^\"]*\";|npmDepsHash = \"$CORRECT_HASH\";|" "$PACKAGE_FILE"

echo "Successfully updated npmDepsHash to: $CORRECT_HASH"
echo "Updated file: $PACKAGE_FILE"
