#!/bin/bash

# MINIMAL SYSTEM GENERATOR - build-binutils-pass1 (LFS-style)
# This script builds binutils pass 1 using LFS methodology

set -e  # Exit on any error
set -x  # Print commands as they execute

# Source environment
source "$(dirname "$0")/00-setup-environment"

# Configuration
BINUTILS_VERSION="2.21"
BINUTILS_SRC_DIR="/usr/src/binutils-${BINUTILS_VERSION}"
BUILD_DIR="/tmp/binutils-build"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== MINIMAL SYSTEM GENERATOR - build-binutils-pass1 ===${NC}"
echo -e "${YELLOW}Building binutils ${BINUTILS_VERSION} pass 1 for ${LFS_TGT}${NC}"

# Check prerequisites
if [ ! -f "${MSG_ROOT}/.headers-prepared" ]; then
    echo -e "${RED}Error: Kernel headers not prepared${NC}"
    echo "Please run prepare-headers first"
    exit 1
fi

if [ ! -d "$BINUTILS_SRC_DIR" ]; then
    echo -e "${RED}Error: Binutils source directory not found: $BINUTILS_SRC_DIR${NC}"
    echo "Expected to find unpacked binutils source at this location"
    exit 1
fi

# Create build directory (LFS recommendation: build in separate directory)
echo -e "${YELLOW}Preparing build directory...${NC}"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Set up documentation bypass
mkdir -p "$BUILD_DIR/bin"
ln -sf /usr/bin/true "$BUILD_DIR/bin/makeinfo"
export PATH="$BUILD_DIR/bin:$PATH"

# Configure binutils pass 1 (LFS method)
echo -e "${YELLOW}Configuring binutils pass 1...${NC}"
echo "Build directory: $BUILD_DIR"
echo "Source directory: $BINUTILS_SRC_DIR"
echo "Target triplet: $LFS_TGT"
echo "Tools prefix: $MSG_TOOLS"

# LFS-style configure for binutils pass 1
"$BINUTILS_SRC_DIR/configure" \
    --prefix="$MSG_TOOLS" \
    --with-sysroot="$MSG_ROOT" \
    --target="$LFS_TGT" \
    --disable-nls \
    --disable-werror

# Build binutils pass 1
echo -e "${YELLOW}Building binutils pass 1...${NC}"
echo "Using ${MAKEFLAGS}"

make

# Install binutils pass 1
echo -e "${YELLOW}Installing binutils pass 1...${NC}"
make install

# Verify installation
if [ -f "${MSG_TOOLS}/bin/${LFS_TGT}-ld" ] && [ -f "${MSG_TOOLS}/bin/${LFS_TGT}-as" ]; then
    echo -e "${GREEN}SUCCESS: Binutils pass 1 installed successfully${NC}"
    echo -e "${GREEN}Cross-linker: ${MSG_TOOLS}/bin/${LFS_TGT}-ld${NC}"
    echo -e "${GREEN}Cross-assembler: ${MSG_TOOLS}/bin/${LFS_TGT}-as${NC}"

    # Show installation summary
    echo -e "${YELLOW}Binutils pass 1 installation summary:${NC}"
    echo "Tools directory: $MSG_TOOLS"
    echo "Target triplet: $LFS_TGT"

    # List key installed cross-tools
    echo -e "${YELLOW}Installed cross-tools:${NC}"
    ls -la "${MSG_TOOLS}/bin/${LFS_TGT}-"* | head -5

    # Check cross-tools directory
    if [ -d "${MSG_TOOLS}/${LFS_TGT}/bin" ]; then
        echo "Cross-tools also installed in: ${MSG_TOOLS}/${LFS_TGT}/bin"
        ls -la "${MSG_TOOLS}/${LFS_TGT}/bin" | head -3
    fi

else
    echo -e "${RED}ERROR: Binutils pass 1 installation failed${NC}"
    echo "Expected cross-tools not found"
    exit 1
fi

# Clean up build directory
echo -e "${YELLOW}Cleaning up build directory...${NC}"
cd /
rm -rf "$BUILD_DIR"

# Create marker file
touch "${MSG_TOOLS}/.binutils-pass1-built"

echo -e "${GREEN}=== build-binutils-pass1 completed successfully ===${NC}"
echo -e "${YELLOW}Next step: run 02-build-gcc-pass1${NC}"
echo -e "${YELLOW}Cross-compilation tools are now available in ${MSG_TOOLS}/bin${NC}"
