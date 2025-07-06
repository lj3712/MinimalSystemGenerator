#!/bin/bash

# MINIMAL SYSTEM GENERATOR - prepare-headers script
# This script prepares and installs kernel headers for the minimal Linux system build

set -e  # Exit on any error
set -x  # Print commands as they execute

# Configuration
KERNEL_VERSION="3.0.101"
KERNEL_SRC_DIR="/usr/src/linux-${KERNEL_VERSION}"
TARGET_ROOT="/opt/target-root"
HEADERS_DIR="${TARGET_ROOT}/usr/include"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== MINIMAL SYSTEM GENERATOR - prepare-headers ===${NC}"
echo -e "${YELLOW}Preparing kernel headers for Linux ${KERNEL_VERSION} (x86_64)${NC}"

# Check if kernel source directory exists
if [ ! -d "$KERNEL_SRC_DIR" ]; then
    echo -e "${RED}Error: Kernel source directory not found: $KERNEL_SRC_DIR${NC}"
    echo "Expected to find unpacked kernel source at this location"
    exit 1
fi

# Create target directories
echo -e "${YELLOW}Creating target directories...${NC}"
mkdir -p "$TARGET_ROOT"
mkdir -p "$HEADERS_DIR"

# Change to kernel source directory
cd "$KERNEL_SRC_DIR"

# Clean any previous header installation attempts
echo -e "${YELLOW}Cleaning previous builds...${NC}"
make mrproper

# Prepare default configuration for headers
echo -e "${YELLOW}Preparing kernel configuration...${NC}"
make defconfig

# Install kernel headers
echo -e "${YELLOW}Installing kernel headers to ${HEADERS_DIR}...${NC}"
make INSTALL_HDR_PATH="${TARGET_ROOT}/usr" headers_install

# Verify headers were installed
if [ -d "${HEADERS_DIR}/linux" ] && [ -d "${HEADERS_DIR}/asm" ]; then
    echo -e "${GREEN}SUCCESS: Kernel headers installed successfully${NC}"
    echo -e "${GREEN}Headers location: ${HEADERS_DIR}${NC}"

    # Show some stats
    echo -e "${YELLOW}Header installation summary:${NC}"
    echo "- Linux headers: $(find ${HEADERS_DIR}/linux -name "*.h" | wc -l) files"
    echo "- ASM headers: $(find ${HEADERS_DIR}/asm* -name "*.h" 2>/dev/null | wc -l) files"
    echo "- Total size: $(du -sh ${HEADERS_DIR} | cut -f1)"
else
    echo -e "${RED}ERROR: Header installation appears to have failed${NC}"
    echo "Expected directories not found in ${HEADERS_DIR}"
    exit 1
fi

# Create a marker file to indicate this step is complete
touch "${TARGET_ROOT}/.headers-prepared"

echo -e "${GREEN}=== prepare-headers completed successfully ===${NC}"
echo -e "${YELLOW}Next step: run build-gcc${NC}"
