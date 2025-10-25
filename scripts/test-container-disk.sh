#!/usr/bin/env bash
set -euo pipefail

# Test script for building and validating the KubeVirt container disk image
# Location: scripts/test-container-disk.sh

echo "🚀 Building KubeVirt container disk image..."
cd "$(dirname "$0")/.."  # Ensure we're in the project root
NIXPKGS_ALLOW_UNFREE=1 nix build .#kubevirt-image --impure

echo "📁 Checking generated files..."
ls -la result/

# Extract the qcow2 file name
QCOW2_FILE=$(find result/ -name "*.qcow2" | head -1)
if [ -z "$QCOW2_FILE" ]; then
    echo "❌ No qcow2 file found!"
    exit 1
fi

echo "✅ Found qcow2 file: $QCOW2_FILE"

# Check file size and type
echo "📊 File information:"
ls -lh "$QCOW2_FILE"
file "$QCOW2_FILE"

# Create a test container disk
echo "🐳 Creating test container disk..."
cp "$QCOW2_FILE" ./test-disk.qcow2

cat > test-Dockerfile << 'EOF'
FROM scratch
ADD test-disk.qcow2 /disk/
EOF

# Build the container image locally
echo "🔨 Building container image..."
docker build -f test-Dockerfile -t terraria-test-container-disk:latest .

# Cleanup
rm -f test-disk.qcow2 test-Dockerfile

echo "✅ Container disk validation complete!"
echo ""
echo "🎯 To deploy to KubeVirt, use the following image reference:"
echo "   ghcr.io/backend-bunny/nix-terraria-container-disk:latest"
echo ""
echo "📖 See README.md for complete KubeVirt deployment examples."