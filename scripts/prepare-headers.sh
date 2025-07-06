#!/bin/bash

# MINIMAL SYSTEM GENERATOR - prepare-headers script (LFS-style)
# This script prepares kernel headers using LFS methodology

set -e  # Exit on any error
set -x  # Print commands as they execute

# Source environment
source "$(dirname "$0")/00-setup-environment"

# Configuration
KERNEL_VERSION="3.0.101"
KERNEL_SRC_DIR="/usr/src/linux-${KERNEL_VERSION}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== MINIMAL SYSTEM GENERATOR - prepare-headers (LFS-style) ===${NC}"
echo -e "${YELLOW}Installing Linux ${KERNEL_VERSION} API headers for ${LFS_TGT}${NC}"

# Check if kernel source directory exists
if [ ! -d "$KERNEL_SRC_DIR" ]; then
    echo -e "${RED}Error: Kernel source directory not found: $KERNEL_SRC_DIR${NC}"
    echo "Expected to find unpacked kernel source at this location"
    exit 1
fi

# Change to kernel source directory
cd "$KERNEL_SRC_DIR"

# Clean any previous builds
echo -e "${YELLOW}Cleaning kernel source...${NC}"
make mrproper

# Install sanitized kernel headers (LFS method)
echo -e "${YELLOW}Installing kernel headers to ${MSG_ROOT}/usr/include...${NC}"
make headers
find usr/include -type f ! -name '*.h' -delete
cp -rv usr/include "${MSG_ROOT}/usr/"

# Verify headers were installed
if [ -d "${MSG_ROOT}/usr/include/linux" ] && [ -d "${MSG_ROOT}/usr/include/asm" ]; then
    echo -e "${GREEN}SUCCESS: Kernel headers installed successfully${NC}"
    echo -e "${GREEN}Headers location: ${MSG_ROOT}/usr/include${NC}"

    # Show some stats
    echo -e "${YELLOW}Header installation summary:${NC}"
    echo "- Linux headers: $(find ${MSG_ROOT}/usr/include/linux -name "*.h" | wc -l) files"
    echo "- ASM headers: $(find ${MSG_ROOT}/usr/include/asm* -name "*.h" 2>/dev/null | wc -l) files"
    echo "- Total size: $(du -sh ${MSG_ROOT}/usr/include | cut -f1)"
else
    echo -e "${RED}ERROR: Header installation appears to have failed${NC}"
    echo "Expected directories not found in ${MSG_ROOT}/usr/include"
    exit 1
fi

# Create a marker file to indicate this step is complete
touch "${MSG_ROOT}/.headers-prepared"

echo -e "${GREEN}=== prepare-headers completed successfully ===${NC}"
echo -e "${YELLOW}Next step: run 01-build-binutils-pass1${NC}"
