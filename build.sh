#!/usr/bin/env bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if nix is available
if ! command -v nix &> /dev/null; then
    print_error "Nix is not installed or not in PATH"
    exit 1
fi

# Check if docker is available
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed or not in PATH"
    exit 1
fi

print_status "Building NixOS tModLoader server Docker image..."

# Build the docker image
if NIXPKGS_ALLOW_UNFREE=1 nix build .#docker --impure; then
    print_status "Successfully built Docker image"
else
    print_error "Failed to build Docker image"
    exit 1
fi

# Load the image into Docker
print_status "Loading Docker image..."
if docker load < result; then
    print_status "Successfully loaded Docker image"
else
    print_error "Failed to load Docker image"
    exit 1
fi

# Clean up the result symlink
rm -f result

print_status "Docker image 'terraria-server:latest' is ready!"
print_status "You can now run it with:"
echo "  docker run -d --name tmodloader-server -p 7777:7777/tcp -p 7777:7777/udp -v tmodloader-data:/var/lib/tmodloader terraria-server:latest"
echo ""
print_status "Or use docker-compose:"
echo "  docker-compose up -d"
echo ""
print_status "Check the README.md for more configuration options."