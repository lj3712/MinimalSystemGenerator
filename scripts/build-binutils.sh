#!/bin/bash

# MINIMAL SYSTEM GENERATOR - build-binutils script
# This script builds binutils 2.21 for installation on the x86_64 target system

set -e  # Exit on any error
set -x  # Print commands as they execute

# Configuration
BINUTILS_VERSION="2.21"
BINUTILS_SRC_DIR="/usr/src/binutils-${BINUTILS_VERSION}"
BUILD_DIR="/tmp/binutils-build"
TARGET_ROOT="/opt/target-root"

# Build configuration
MAKE_JOBS=$(nproc)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== MINIMAL SYSTEM GENERATOR - build-binutils ===${NC}"
echo -e "${YELLOW}Building binutils ${BINUTILS_VERSION} for x86_64 target system${NC}"

# Check prerequisites
if [ ! -f "${TARGET_ROOT}/.gcc-built" ]; then
    echo -e "${RED}Error: GCC not built${NC}"
    echo "Please run build-gcc first"
    exit 1
fi

if [ ! -d "$BINUTILS_SRC_DIR" ]; then
    echo -e "${RED}Error: Binutils source directory not found: $BINUTILS_SRC_DIR${NC}"
    echo "Expected to find unpacked binutils source at this location"
    exit 1
fi

# Create build directory
echo -e "${YELLOW}Preparing build directory...${NC}"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Set up environment to disable documentation generation
export MAKEINFO=missing

# Create a fake makeinfo to ensure documentation is skipped
echo -e "${YELLOW}Setting up documentation bypass...${NC}"
mkdir -p "$BUILD_DIR/bin"
ln -sf /usr/bin/true "$BUILD_DIR/bin/makeinfo"
export PATH="$BUILD_DIR/bin:$PATH"

# Configure binutils for target installation
echo -e "${YELLOW}Configuring binutils...${NC}"
echo "Build directory: $BUILD_DIR"
echo "Source directory: $BINUTILS_SRC_DIR"
echo "Target root: $TARGET_ROOT"
echo "Using container's native toolchain to build"

# Configure binutils to be installed and run on the target system
"$BINUTILS_SRC_DIR/configure" \
    --prefix=/usr \
    --with-sysroot="" \
    --enable-shared \
    --enable-threads \
    --enable-plugins \
    --enable-64-bit-bfd \
    --disable-werror \
    --disable-nls \
    --with-system-zlib \
    MAKEINFO=missing

# Build binutils using container's toolchain
echo -e "${YELLOW}Building binutils (this may take a while)...${NC}"
echo "Using ${MAKE_JOBS} parallel jobs"

make -j"$MAKE_JOBS"

# Install binutils to target root filesystem
echo -e "${YELLOW}Installing binutils to target root...${NC}"
make DESTDIR="$TARGET_ROOT" MAKEINFO=missing install

# Verify installation
if [ -f "${TARGET_ROOT}/usr/bin/ld" ] && [ -f "${TARGET_ROOT}/usr/bin/as" ]; then
    echo -e "${GREEN}SUCCESS: Binutils installed successfully${NC}"
    echo -e "${GREEN}Linker location: ${TARGET_ROOT}/usr/bin/ld${NC}"
    echo -e "${GREEN}Assembler location: ${TARGET_ROOT}/usr/bin/as${NC}"

    # Show installation summary
    echo -e "${YELLOW}Binutils installation summary:${NC}"
    echo "Target root: $TARGET_ROOT"
    echo "Install prefix: /usr (within target)"

    # List key installed tools
    echo -e "${YELLOW}Key installed tools:${NC}"
    find "${TARGET_ROOT}/usr/bin" -name "*ld*" -o -name "*as*" -o -name "*ar*" -o -name "*nm*" -o -name "*objdump*" -o -name "*strip*" 2>/dev/null | head -10

    # Check libraries
    if [ -d "${TARGET_ROOT}/usr/lib" ]; then
        echo "Binutils libraries: $(find ${TARGET_ROOT}/usr/lib -name "*bfd*" -o -name "*opcodes*" 2>/dev/null | wc -l) files"
    fi

    # Check total size
    echo "Total binutils installation size: $(du -sh ${TARGET_ROOT}/usr | cut -f1)"

else
    echo -e "${RED}ERROR: Binutils installation appears to have failed${NC}"
    echo "Expected tools not found: ${TARGET_ROOT}/usr/bin/ld or ${TARGET_ROOT}/usr/bin/as"
    exit 1
fi

# Clean up build directory to save space
echo -e "${YELLOW}Cleaning up build directory...${NC}"
cd /
rm -rf "$BUILD_DIR"

# Create a marker file to indicate this step is complete
touch "${TARGET_ROOT}/.binutils-built"

echo -e "${GREEN}=== build-binutils completed successfully ===${NC}"
echo -e "${YELLOW}Next step: run build-glibc${NC}"
echo -e "${YELLOW}Target system now has complete development tools (GCC + binutils)${NC}"
