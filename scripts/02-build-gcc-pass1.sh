#!/bin/bash

# MINIMAL SYSTEM GENERATOR - build-gcc-pass1 (LFS-style)
# This script builds GCC pass 1 using LFS methodology

set -e  # Exit on any error
set -x  # Print commands as they execute

# Source environment
source "$(dirname "$0")/00-setup-environment"

# Configuration
GCC_VERSION="4.5.2"
GCC_SRC_DIR="/usr/src/gcc-${GCC_VERSION}"
BUILD_DIR="/tmp/gcc-build"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== MINIMAL SYSTEM GENERATOR - build-gcc-pass1 ===${NC}"
echo -e "${YELLOW}Building GCC ${GCC_VERSION} pass 1 for ${LFS_TGT}${NC}"

# Check prerequisites
if [ ! -f "${MSG_TOOLS}/.binutils-pass1-built" ]; then
    echo -e "${RED}Error: Binutils pass 1 not built${NC}"
    echo "Please run 01-build-binutils-pass1 first"
    exit 1
fi

if [ ! -d "$GCC_SRC_DIR" ]; then
    echo -e "${RED}Error: GCC source directory not found: $GCC_SRC_DIR${NC}"
    echo "Expected to find unpacked GCC source at this location"
    exit 1
fi

# Create build directory (LFS requirement)
echo -e "${YELLOW}Preparing build directory...${NC}"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Set up documentation bypass
mkdir -p "$BUILD_DIR/bin"
ln -sf /usr/bin/true "$BUILD_DIR/bin/makeinfo"
export PATH="$BUILD_DIR/bin:$MSG_TOOLS/bin:$PATH"

# GCC requires GMP, MPFR, and MPC - check if they need to be unpacked in GCC source
echo -e "${YELLOW}Checking GCC prerequisites...${NC}"
cd "$GCC_SRC_DIR"

# Note: In a real build, these would be extracted here if not already present
# For LFS, these are typically extracted into the GCC source directory
if [ ! -d "gmp" ] && [ -f "../gmp-*.tar.*" ]; then
    echo "Extracting GMP into GCC source..."
    tar -xf ../gmp-*.tar.*
    mv gmp-* gmp 2>/dev/null || true
fi

if [ ! -d "mpfr" ] && [ -f "../mpfr-*.tar.*" ]; then
    echo "Extracting MPFR into GCC source..."
    tar -xf ../mpfr-*.tar.*
    mv mpfr-* mpfr 2>/dev/null || true
fi

if [ ! -d "mpc" ] && [ -f "../mpc-*.tar.*" ]; then
    echo "Extracting MPC into GCC source..."
    tar -xf ../mpc-*.tar.*
    mv mpc-* mpc 2>/dev/null || true
fi

# On x86_64, ensure libraries go to lib not lib64 (LFS approach)
case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
 ;;
esac

# Return to build directory
cd "$BUILD_DIR"

# Configure GCC pass 1 (LFS method)
echo -e "${YELLOW}Configuring GCC pass 1...${NC}"
echo "Build directory: $BUILD_DIR"
echo "Source directory: $GCC_SRC_DIR"
echo "Target triplet: $LFS_TGT"
echo "Tools prefix: $MSG_TOOLS"

# LFS-style configure for GCC pass 1 (adapted for older GCC 4.5.2)
"$GCC_SRC_DIR/configure" \
    --target="$LFS_TGT" \
    --prefix="$MSG_TOOLS" \
    --with-sysroot="$MSG_ROOT" \
    --with-newlib \
    --without-headers \
    --disable-nls \
    --disable-shared \
    --disable-multilib \
    --disable-decimal-float \
    --disable-threads \
    --disable-libmudflap \
    --disable-libssp \
    --disable-libgomp \
    --disable-libquadmath \
    --enable-languages=c \
    MAKEINFO=missing

# Build GCC pass 1 (only what's needed)
echo -e "${YELLOW}Building GCC pass 1 (this will take a while)...${NC}"
echo "Using ${MAKEFLAGS}"

# Build only the compiler and essential libraries
make all-gcc all-target-libgcc

# Install GCC pass 1
echo -e "${YELLOW}Installing GCC pass 1...${NC}"
make install-gcc install-target-libgcc

# Verify installation
if [ -f "${MSG_TOOLS}/bin/${LFS_TGT}-gcc" ]; then
    echo -e "${GREEN}SUCCESS: GCC pass 1 installed successfully${NC}"
    echo -e "${GREEN}Cross-compiler: ${MSG_TOOLS}/bin/${LFS_TGT}-gcc${NC}"

    # Show installation summary
    echo -e "${YELLOW}GCC pass 1 installation summary:${NC}"
    echo "Cross-compiler: ${MSG_TOOLS}/bin/${LFS_TGT}-gcc"
    echo "Target triplet: $LFS_TGT"

    # Test cross-compiler
    echo -e "${YELLOW}Testing cross-compiler...${NC}"
    "${MSG_TOOLS}/bin/${LFS_TGT}-gcc" --version | head -n1
    echo "Target: $(${MSG_TOOLS}/bin/${LFS_TGT}-gcc -dumpmachine)"

    # Check libgcc
    if [ -d "${MSG_TOOLS}/lib/gcc" ]; then
        echo "libgcc location: $(find ${MSG_TOOLS}/lib/gcc -name libgcc.a | head -1)"
    fi

else
    echo -e "${RED}ERROR: GCC pass 1 installation failed${NC}"
    echo "Expected cross-compiler not found: ${MSG_TOOLS}/bin/${LFS_TGT}-gcc"
    exit 1
fi

# Clean up build directory
echo -e "${YELLOW}Cleaning up build directory...${NC}"
cd /
rm -rf "$BUILD_DIR"

# Create marker file
touch "${MSG_TOOLS}/.gcc-pass1-built"

echo -e "${GREEN}=== build-gcc-pass1 completed successfully ===${NC}"
echo -e "${YELLOW}Next step: run 03-build-glibc${NC}"
echo -e "${YELLOW}Cross-compilation toolchain is now ready!${NC}"
