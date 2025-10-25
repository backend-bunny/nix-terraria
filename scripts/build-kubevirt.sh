#!/usr/bin/env bash
set -euo pipefail

# Build script for KubeVirt images
# Usage: ./scripts/build-kubevirt.sh [vm-image|kubevirt-image]

cd "$(dirname "$0")/.."

TARGET="${1:-kubevirt-image}"

echo "🚀 Building $TARGET..."

case "$TARGET" in
  "vm-image")
    echo "Building traditional VM image for local testing..."
    NIXPKGS_ALLOW_UNFREE=1 nix build .#vm-image --impure
    echo "✅ VM image built: $(readlink result)"
    echo "Run with: ./result/bin/run-terraria-server-vm"
    ;;
  "kubevirt-image")
    echo "Building KubeVirt container disk image..."
    NIXPKGS_ALLOW_UNFREE=1 nix build .#kubevirt-image --impure
    QCOW2_FILE=$(find result/ -name "*.qcow2" | head -1)
    echo "✅ KubeVirt image built: $QCOW2_FILE"
    echo "Size: $(du -h "$QCOW2_FILE" | cut -f1)"
    echo "Use with: kubectl apply -f KUBEVIRT.md examples"
    ;;
  *)
    echo "❌ Unknown target: $TARGET"
    echo "Usage: $0 [vm-image|kubevirt-image]"
    exit 1
    ;;
esac

echo ""
echo "📖 See README.md and KUBEVIRT.md for deployment instructions."