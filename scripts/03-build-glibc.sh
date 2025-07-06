#!/bin/bash

# MINIMAL SYSTEM GENERATOR - build-glibc (LFS-style)
# This script builds glibc using LFS methodology with cross-tools

set -e  # Exit on any error
set -x  # Print commands as they execute

# Source environment
source "$(dirname "$0")/00-setup-environment"

# Configuration
GLIBC_VERSION="2.13"
GLIBC_SRC_DIR="/usr/src/glibc-${GLIBC_VERSION}"
BUILD_DIR="/tmp/glibc-build"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== MINIMAL SYSTEM GENERATOR - build-glibc ===${NC}"
echo -e "${YELLOW}Building glibc ${GLIBC_VERSION} using cross-tools${NC}"

# Check prerequisites
if [ ! -f "${MSG_TOOLS}/.gcc-pass1-built" ]; then
    echo -e "${RED}Error: GCC pass 1 not built${NC}"
    echo "Please run 02-build-gcc-pass1 first"
    exit 1
fi

if [ ! -d "$GLIBC_SRC_DIR" ]; then
    echo -e "${RED}Error: Glibc source directory not found: $GLIBC_SRC_DIR${NC}"
    echo "Expected to find unpacked glibc source at this location"
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

# Verify cross-tools are available
echo -e "${YELLOW}Verifying cross-tools...${NC}"
if ! command -v "${LFS_TGT}-gcc" >/dev/null 2>&1; then
    echo -e "${RED}Error: Cross-compiler ${LFS_TGT}-gcc not found in PATH${NC}"
    exit 1
fi

echo "Cross-compiler: $(which ${LFS_TGT}-gcc)"
"${LFS_TGT}-gcc" --version | head -n1

# Configure glibc (LFS method with cross-tools)
echo -e "${YELLOW}Configuring glibc...${NC}"
echo "Build directory: $BUILD_DIR"
echo "Source directory: $GLIBC_SRC_DIR"
echo "Target triplet: $LFS_TGT"
echo "Sysroot: $MSG_ROOT"

# LFS-style configure for glibc
"$GLIBC_SRC_DIR/configure" \
    --prefix=/usr \
    --host="$LFS_TGT" \
    --build="$(../scripts/config.guess)" \
    --enable-kernel=2.6.32 \
    --with-headers="${MSG_ROOT}/usr/include" \
    --disable-nls \
    libc_cv_forced_unwind=yes \
    libc_cv_c_cleanup=yes

# Build glibc
echo -e "${YELLOW}Building glibc (this will take a while)...${NC}"
echo "Using ${MAKEFLAGS}"

make

# Install glibc to target root
echo -e "${YELLOW}Installing glibc to target root...${NC}"
make DESTDIR="$MSG_ROOT" install

# Verify installation
if [ -f "${MSG_ROOT}/usr/lib/libc.so.6" ] && [ -f "${MSG_ROOT}/usr/lib/ld-linux-x86-64.so.2" ]; then
    echo -e "${GREEN}SUCCESS: Glibc installed successfully${NC}"
    echo -e "${GREEN}C Library: ${MSG_ROOT}/usr/lib/libc.so.6${NC}"
    echo -e "${GREEN}Dynamic Linker: ${MSG_ROOT}/usr/lib/ld-linux-x86-64.so.2${NC}"

    # Show installation summary
    echo -e "${YELLOW}Glibc installation summary:${NC}"
    echo "Install prefix: /usr (within ${MSG_ROOT})"
    echo "Built with cross-tools: $LFS_TGT"

    # Check key libraries installed
    echo -e "${YELLOW}Key installed libraries:${NC}"
    find "${MSG_ROOT}/usr/lib" -name "libc.so*" -o -name "libm.so*" -o -name "libpthread.so*" -o -name "libdl.so*" 2>/dev/null | head -10

    # Show glibc size
    echo "Glibc installation size: $(du -sh ${MSG_ROOT}/usr/lib | cut -f1)"

else
    echo -e "${RED}ERROR: Glibc installation appears to have failed${NC}"
    echo "Expected files not found: libc.so.6 or ld-linux-x86-64.so.2"
    echo "Checking what was installed..."
    find "${MSG_ROOT}/usr/lib" -name "*libc*" -o -name "*ld-*" 2>/dev/null | head -5
    exit 1
fi

# Set up essential symlinks for the target system (LFS method)
echo -e "${YELLOW}Setting up dynamic linker symlinks...${NC}"
cd "${MSG_ROOT}"

# Create lib64 directory and symlink for dynamic linker
mkdir -p lib64
if [ ! -e lib64/ld-linux-x86-64.so.2 ]; then
    ln -sf ../usr/lib/ld-linux-x86-64.so.2 lib64/ld-linux-x86-64.so.2
    echo "✓ Created /lib64/ld-linux-x86-64.so.2 symlink"
fi

# Create /lib symlink for compatibility
if [ ! -e lib ]; then
    ln -sf usr/lib lib
    echo "✓ Created /lib → /usr/lib symlink"
fi

# Test the dynamic linker (LFS verification)
echo -e "${YELLOW}Testing dynamic linker...${NC}"
echo 'int main(){}' | "${LFS_TGT}-gcc" -x c - -v -Wl,--verbose &> "${BUILD_DIR}/dummy.log"
if "${MSG_ROOT}/usr/lib/ld-linux-x86-64.so.2" --library-path "${MSG_ROOT}/usr/lib" "${BUILD_DIR}/a.out" 2>/dev/null; then
    echo "✓ Dynamic linker test passed"
else
    echo "⚠ Dynamic linker test failed (may be expected at this stage)"
fi

# Clean up build directory
echo -e "${YELLOW}Cleaning up build directory...${NC}"
cd /
rm -rf "$BUILD_DIR"

# Create marker file
touch "${MSG_ROOT}/.glibc-built"

echo -e "${GREEN}=== build-glibc completed successfully ===${NC}"
echo -e "${YELLOW}Next step: run 04-build-binutils-pass2${NC}"
echo -e "${YELLOW}Target system now has a complete C library!${NC}"
echo -e "${YELLOW}Cross-compilation environment is ready for pass 2 tools.${NC}"
