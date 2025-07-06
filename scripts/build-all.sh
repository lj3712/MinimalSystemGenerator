#!/bin/bash

# MINIMAL SYSTEM GENERATOR - Build All (LFS-style)
# This script runs the complete LFS-style build process

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(dirname "$0")"

echo -e "${GREEN}=== MINIMAL SYSTEM GENERATOR - Complete Build ===${NC}"
echo -e "${YELLOW}Starting LFS-style automated build process${NC}"

# Set up environment
echo -e "${YELLOW}Phase 0: Setting up build environment...${NC}"
source "${SCRIPT_DIR}/00-setup-environment"

# Phase 1: Headers
echo -e "${YELLOW}Phase 1: Installing kernel headers...${NC}"
"${SCRIPT_DIR}/prepare-headers"

# Phase 2: Cross-tools Pass 1
echo -e "${YELLOW}Phase 2: Building cross-binutils (pass 1)...${NC}"
"${SCRIPT_DIR}/01-build-binutils-pass1"

echo -e "${YELLOW}Phase 3: Building cross-GCC (pass 1)...${NC}"
"${SCRIPT_DIR}/02-build-gcc-pass1"

# Phase 3: Target C library
echo -e "${YELLOW}Phase 4: Building target glibc...${NC}"
"${SCRIPT_DIR}/03-build-glibc"

# Phase 4: Full toolchain (when scripts are ready)
if [ -f "${SCRIPT_DIR}/04-build-binutils-pass2" ]; then
    echo -e "${YELLOW}Phase 5: Building binutils (pass 2)...${NC}"
    "${SCRIPT_DIR}/04-build-binutils-pass2"
fi

if [ -f "${SCRIPT_DIR}/05-build-gcc-pass2" ]; then
    echo -e "${YELLOW}Phase 6: Building GCC (pass 2)...${NC}"
    "${SCRIPT_DIR}/05-build-gcc-pass2"
fi

# Phase 5: System components (when scripts are ready)
if [ -f "${SCRIPT_DIR}/build-kernel" ]; then
    echo -e "${YELLOW}Phase 7: Building Linux kernel...${NC}"
    "${SCRIPT_DIR}/build-kernel"
fi

if [ -f "${SCRIPT_DIR}/build-busybox" ]; then
    echo -e "${YELLOW}Phase 8: Building busybox...${NC}"
    "${SCRIPT_DIR}/build-busybox"
fi

if [ -f "${SCRIPT_DIR}/build-rootfs" ]; then
    echo -e "${YELLOW}Phase 9: Preparing root filesystem...${NC}"
    "${SCRIPT_DIR}/build-rootfs"
fi

if [ -f "${SCRIPT_DIR}/tar-rootfs" ]; then
    echo -e "${YELLOW}Phase 10: Creating root filesystem tarball...${NC}"
    "${SCRIPT_DIR}/tar-rootfs"
fi

# Summary
echo -e "${GREEN}=== BUILD COMPLETE ===${NC}"
echo -e "${YELLOW}Build summary:${NC}"
echo "Target triplet: $LFS_TGT"
echo "Cross-tools: $MSG_TOOLS"
echo "Target root: $MSG_ROOT"
echo ""
echo "Total target system size: $(du -sh $MSG_ROOT | cut -f1)"
if [ -d "$MSG_TOOLS" ]; then
    echo "Cross-tools size: $(du -sh $MSG_TOOLS | cut -f1)"
fi
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Exit container"
echo "2. Run host-build-image to create VM disk image"
echo "3. Boot target system in VM"
echo ""
echo -e "${GREEN}LFS-style minimal system build completed successfully!${NC}"
