#!/bin/bash

# MINIMAL SYSTEM GENERATOR - build-gcc script
# This script builds GCC 4.5.2 for installation on the target system

set -e  # Exit on any error
set -x  # Print commands as they execute

# Configuration
GCC_VERSION="4.5.2"
GCC_SRC_DIR="/usr/src/gcc-${GCC_VERSION}"
BUILD_DIR="/tmp/gcc-build"
TARGET_ROOT="/opt/target-root"

# Build configuration
MAKE_JOBS=$(nproc)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== MINIMAL SYSTEM GENERATOR - build-gcc ===${NC}"
echo -e "${YELLOW}Building GCC ${GCC_VERSION} for x86_64 target system${NC}"

# Check prerequisites
if [ ! -f "${TARGET_ROOT}/.headers-prepared" ]; then
    echo -e "${RED}Error: Kernel headers not prepared${NC}"
    echo "Please run prepare-headers first"
    exit 1
fi

if [ ! -d "$GCC_SRC_DIR" ]; then
    echo -e "${RED}Error: GCC source directory not found: $GCC_SRC_DIR${NC}"
    echo "Expected to find unpacked GCC source at this location"
    exit 1
fi

# Create target root and build directories
echo -e "${YELLOW}Preparing directories...${NC}"
mkdir -p "$TARGET_ROOT"
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

# Configure GCC for target installation
echo -e "${YELLOW}Configuring GCC...${NC}"
echo "Build directory: $BUILD_DIR"
echo "Source directory: $GCC_SRC_DIR"
echo "Target root: $TARGET_ROOT"
echo "Using container's native toolchain to build"

# Configure GCC to be installed and run on the target system
"$GCC_SRC_DIR/configure" \
    --prefix=/usr \
    --with-sysroot="" \
    --enable-languages=c,c++ \
    --enable-shared \
    --enable-threads=posix \
    --enable-checking=release \
    --enable-multilib \
    --with-system-zlib \
    --enable-__cxa_atexit \
    --disable-libunwind-exceptions \
    --enable-gnu-unique-object \
    --enable-linker-build-id \
    --with-linker-hash-style=gnu \
    --enable-plugin \
    --enable-initfini-array \
    --disable-libgcj \
    --disable-nls \
    --with-tune=generic \
    --with-arch_64=x86-64 \
    MAKEINFO=missing

# Build GCC using container's toolchain
echo -e "${YELLOW}Building GCC (this may take a while)...${NC}"
echo "Using ${MAKE_JOBS} parallel jobs"

# Set MAKEINFO=missing to avoid documentation build issues
export MAKEINFO=missing
make -j"$MAKE_JOBS"

# Install GCC to target root filesystem
echo -e "${YELLOW}Installing GCC to target root...${NC}"
make DESTDIR="$TARGET_ROOT" MAKEINFO=missing install

# Verify installation
if [ -f "${TARGET_ROOT}/usr/bin/gcc" ]; then
    echo -e "${GREEN}SUCCESS: GCC installed successfully${NC}"
    echo -e "${GREEN}GCC location: ${TARGET_ROOT}/usr/bin/gcc${NC}"

    # Show installation summary
    echo -e "${YELLOW}GCC installation summary:${NC}"
    echo "Target root: $TARGET_ROOT"
    echo "Install prefix: /usr (within target)"

    # List key installed files
    echo -e "${YELLOW}Key installed files:${NC}"
    find "${TARGET_ROOT}/usr/bin" -name "*gcc*" -o -name "*g++*" -o -name "cpp" 2>/dev/null | head -10

    # Check libraries
    if [ -d "${TARGET_ROOT}/usr/lib/gcc" ]; then
        echo "GCC libraries: $(find ${TARGET_ROOT}/usr/lib/gcc -type f | wc -l) files"
    fi

    # Check total size
    echo "Total GCC installation size: $(du -sh ${TARGET_ROOT}/usr | cut -f1)"

else
    echo -e "${RED}ERROR: GCC installation appears to have failed${NC}"
    echo "Expected compiler not found: ${TARGET_ROOT}/usr/bin/gcc"
    exit 1
fi

# Clean up build directory to save space
echo -e "${YELLOW}Cleaning up build directory...${NC}"
cd /
rm -rf "$BUILD_DIR"

# Create a marker file to indicate this step is complete
touch "${TARGET_ROOT}/.gcc-built"

echo -e "${GREEN}=== build-gcc completed successfully ===${NC}"
echo -e "${YELLOW}Next step: run build-binutils${NC}"
echo -e "${YELLOW}Target system will have a complete x86_64 GCC installation at /usr${NC}"
