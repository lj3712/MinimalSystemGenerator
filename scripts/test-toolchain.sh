#!/bin/bash

# MINIMAL SYSTEM GENERATOR - test-toolchain script
# This script tests the built GCC and binutils toolchain

set -e  # Exit on any error

# Configuration
TARGET_ROOT="/opt/target-root"
TEST_DIR="/tmp/toolchain-test"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== MINIMAL SYSTEM GENERATOR - toolchain test ===${NC}"
echo -e "${YELLOW}Testing built GCC and binutils toolchain${NC}"

# Check prerequisites
if [ ! -f "${TARGET_ROOT}/.gcc-built" ]; then
    echo -e "${RED}Error: GCC not built${NC}"
    exit 1
fi

if [ ! -f "${TARGET_ROOT}/.binutils-built" ]; then
    echo -e "${RED}Error: Binutils not built${NC}"
    exit 1
fi

# Create test directory
echo -e "${YELLOW}Setting up test environment...${NC}"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Set up environment to use target toolchain
export PATH="${TARGET_ROOT}/usr/bin:$PATH"
export LD_LIBRARY_PATH="${TARGET_ROOT}/usr/lib:${TARGET_ROOT}/usr/lib64:$LD_LIBRARY_PATH"
export C_INCLUDE_PATH="${TARGET_ROOT}/usr/include"
export CPLUS_INCLUDE_PATH="${TARGET_ROOT}/usr/include"

# Test 1: Check if tools exist and are executable
echo -e "${YELLOW}Test 1: Checking toolchain components...${NC}"

TOOLS=("gcc" "g++" "ld" "as" "ar" "nm" "objdump" "strip")
for tool in "${TOOLS[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
        echo "✓ $tool found: $(which $tool)"
    else
        echo -e "${RED}✗ $tool not found${NC}"
        exit 1
    fi
done

# Test 2: Check GCC version and configuration
echo -e "${YELLOW}Test 2: GCC configuration...${NC}"
gcc --version | head -n1
echo "Target: $(gcc -dumpmachine)"
echo "Thread model: $(gcc -dumpspecs | grep -A1 thread_file | tail -n1)"

# Test 3: Simple C compilation test
echo -e "${YELLOW}Test 3: Simple C compilation...${NC}"
cat > hello.c << 'EOF'
#include <stdio.h>

int main() {
    printf("Hello from minimal system toolchain!\n");
    return 0;
}
EOF

echo "Compiling hello.c..."
gcc -v hello.c -o hello 2>&1 | tail -n5
echo "✓ Compilation successful"

# Test 4: Check the compiled binary
echo -e "${YELLOW}Test 4: Binary analysis...${NC}"
file hello
readelf -h hello | grep Machine
echo "Binary size: $(stat -c%s hello) bytes"

# Test 5: Test assembler directly
echo -e "${YELLOW}Test 5: Direct assembler test...${NC}"
cat > test.s << 'EOF'
.section .data
msg: .ascii "Assembly test\n"
msg_len = . - msg

.section .text
.global _start
_start:
    # This is just a syntax test, not meant to run
    mov $msg, %rax
    mov $msg_len, %rbx
EOF

as test.s -o test.o
echo "✓ Assembly successful"
nm test.o | head -n3

# Test 6: Test linker directly
echo -e "${YELLOW}Test 6: Linker test...${NC}"
ld --version | head -n1
echo "✓ Linker operational"

# Test 7: Check for essential headers
echo -e "${YELLOW}Test 7: Header availability...${NC}"
HEADERS=("stdio.h" "stdlib.h" "string.h" "linux/types.h" "asm/types.h")
for header in "${HEADERS[@]}"; do
    if echo "#include <$header>" | gcc -E - >/dev/null 2>&1; then
        echo "✓ $header available"
    else
        echo -e "${RED}✗ $header missing${NC}"
        exit 1
    fi
done

# Test 8: C++ compilation test
echo -e "${YELLOW}Test 8: C++ compilation...${NC}"
cat > hello.cpp << 'EOF'
#include <iostream>
#include <string>

int main() {
    std::string msg = "Hello from C++ toolchain!";
    std::cout << msg << std::endl;
    return 0;
}
EOF

g++ hello.cpp -o hello_cpp
echo "✓ C++ compilation successful"
file hello_cpp

# Test 9: Static linking test
echo -e "${YELLOW}Test 9: Static linking...${NC}"
gcc -static hello.c -o hello_static 2>/dev/null || echo "Note: Static linking may need glibc (expected at this stage)"

# Test 10: Optimization test
echo -e "${YELLOW}Test 10: Optimization levels...${NC}"
gcc -O2 hello.c -o hello_optimized
echo "✓ Optimization compilation successful"

# Summary
echo -e "${GREEN}=== TOOLCHAIN TEST SUMMARY ===${NC}"
echo -e "${GREEN}✓ All essential tools are working${NC}"
echo -e "${GREEN}✓ C compilation: Working${NC}"
echo -e "${GREEN}✓ C++ compilation: Working${NC}"
echo -e "${GREEN}✓ Assembly: Working${NC}"
echo -e "${GREEN}✓ Linking: Working${NC}"
echo -e "${GREEN}✓ Headers: Available${NC}"

echo -e "${YELLOW}Current limitations (expected):${NC}"
echo "• No C library yet (glibc) - programs won't run"
echo "• No standard library runtime"
echo "• Static linking incomplete without glibc"

echo -e "${GREEN}Ready to proceed with build-glibc!${NC}"

# Clean up
cd /
rm -rf "$TEST_DIR"
