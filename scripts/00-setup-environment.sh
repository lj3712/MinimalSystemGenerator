#!/bin/bash

# MINIMAL SYSTEM GENERATOR - LFS-style environment setup
# This script sets up the build environment using LFS methodology

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== MINIMAL SYSTEM GENERATOR - Environment Setup ===${NC}"
echo -e "${YELLOW}Setting up LFS-style build environment${NC}"

# LFS-style target triplet (isolates from host)
export LFS_TGT=$(uname -m)-msg-linux-gnu

# Target root filesystem (final system)
export MSG_ROOT="/opt/target-root"

# Temporary tools directory (LFS-style)
export MSG_TOOLS="/opt/tools"

# Set PATH to prefer our tools
export PATH="$MSG_TOOLS/bin:$PATH"

# Disable hash caching for bash
set +h

# Set make flags
export MAKEFLAGS="-j$(nproc)"

# Disable documentation generation globally
export MAKEINFO=missing

echo -e "${YELLOW}Environment configuration:${NC}"
echo "Target triplet: $LFS_TGT"
echo "Target root: $MSG_ROOT"
echo "Tools directory: $MSG_TOOLS"
echo "PATH: $PATH"
echo "Make jobs: $(nproc)"

# Create required directories
echo -e "${YELLOW}Creating build directories...${NC}"
mkdir -p "$MSG_ROOT"
mkdir -p "$MSG_TOOLS"

# Ensure directories are writable
chmod 755 "$MSG_ROOT" "$MSG_TOOLS"

echo -e "${GREEN}Environment setup complete${NC}"
echo -e "${YELLOW}Run 'source 00-setup-environment' or include it in other scripts${NC}"
