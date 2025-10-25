# Scripts Directory

This directory contains build and test scripts for the NixOS tModLoader server.

## Available Scripts

### `build-kubevirt.sh`
Build script for creating VM and KubeVirt images.

```bash
# Build KubeVirt container disk image (default)
./scripts/build-kubevirt.sh

# Build traditional VM image for local testing
./scripts/build-kubevirt.sh vm-image

# Build KubeVirt image explicitly
./scripts/build-kubevirt.sh kubevirt-image
```

### `test-container-disk.sh`
Test script for validating container disk image creation.

```bash
# Run container disk validation test
./scripts/test-container-disk.sh
```

This script:
1. Builds the KubeVirt image
2. Creates a test container disk image
3. Validates the container can be built
4. Cleans up test artifacts

## Usage from Project Root

All scripts should be run from the project root directory:

```bash
cd /path/to/nix-terraria
./scripts/build-kubevirt.sh
```

The scripts automatically handle changing to the correct directory if run from elsewhere.