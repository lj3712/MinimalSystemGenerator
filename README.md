# Minimal System Generator

A collection of build scripts to create a minimal x86_64 Linux system with kernel, GCC, binutils, glibc, and busybox. The resulting system is designed to run under a virtual machine (QEMU, VMware, etc.) and is capable of compiling and executing programs.

## System Specifications

- **Linux kernel**: 3.0.101
- **GCC**: 4.5.2
- **Binutils**: 2.21
- **Glibc**: 2.13
- **Busybox**: 1.21.1

## Build Environment

- **Host OS**: Debian bookworm
- **Container**: Fedora 20 (podman)
- **Target Architecture**: x86_64 (64-bit x86)
- **Target Root**: `/opt/target-root`

## Prerequisites

### Container Dependencies (Fedora 20)
```bash
yum install zlib-devel
```
*Note: Standard x86_64 development packages are included in base container setup*

### Source Requirements
All source tarballs must be available and extracted in `/usr/src/`:
- `/usr/src/linux-3.0.101/`
- `/usr/src/gcc-4.5.2/`
- `/usr/src/binutils-2.21/`
- `/usr/src/glibc-2.13/`
- `/usr/src/busybox-1.21.1/`

## Build Order

The scripts are designed to be run in this specific order:

1. ✅ **prepare-headers** - Unpacks and installs kernel headers
2. ✅ **build-gcc** - Builds GCC compiler for target system
3. 🔄 **build-binutils** - Builds binutils (assembler, linker, etc.)
4. 🔄 **build-glibc** - Builds C library
5. 🔄 **build-kernel** - Builds Linux kernel
6. 🔄 **build-busybox** - Builds minimal userspace utilities
7. 🔄 **build-rootfs** - Prepares root filesystem structure
8. 🔄 **tar-rootfs** - Creates tarball of root filesystem
9. 🔄 **host-build-image** - Creates disk image for VM (runs on host)

*Note: Another build order may be optimal depending on dependencies.*

## Usage

### Individual Scripts
```bash
# Run scripts in order from container
./scripts/prepare-headers
./scripts/build-gcc
./scripts/build-binutils
# ... continue with remaining scripts
```

### Automated Build
```bash
# Run all container steps automatically
./scripts/build-all
```

### Creating VM Image
```bash
# After exiting container, run on host
./scripts/host-build-image
```

## Directory Structure

```
/opt/target-root/          # Target root filesystem
├── usr/
│   ├── bin/               # Target system executables (gcc, etc.)
│   ├── lib/               # Target system libraries
│   ├── include/           # Kernel and system headers
│   └── share/             # Documentation, man pages, etc.
├── bin/                   # Essential binaries (from busybox)
├── sbin/                  # System binaries
├── etc/                   # Configuration files
├── dev/                   # Device files
├── proc/                  # Process filesystem mount point
├── sys/                   # Sysfs mount point
└── tmp/                   # Temporary files
```

## Known Issues & Solutions

### Texinfo Compatibility
GCC 4.5.2 has documentation files incompatible with modern texinfo (5.0+).

**Solution Applied**:
- Set `MAKEINFO=missing` in environment and configure
- Create fake `makeinfo` script pointing to `/usr/bin/true`
- Add fake script directory to beginning of PATH

### Missing Development Headers
Some packages require development headers not included in base container.

**Solutions**:
- `zlib.h` missing → Install `zlib-devel`

## Build Process Details

### Cross-Compilation vs Native Build
This project uses **native compilation** within the Fedora 20 container. Both the container and target system are x86_64 architecture, so the container's GCC builds target components directly without cross-compilation complexity. Components are installed to the target root filesystem with `DESTDIR`.

### Target System Self-Hosting
The resulting minimal system includes a complete GCC installation, allowing it to compile programs for itself. This makes it truly self-contained for development purposes.

## Output

After successful completion:
- **Container**: `/opt/target-root/` contains complete target filesystem
- **Host**: Bootable VM disk image ready for use with QEMU/VMware

## Testing

The minimal system should be capable of:
- Booting in a virtual machine
- Running basic shell commands (via busybox)
- Compiling and executing C/C++ programs
- Basic file operations and system utilities

## Contributing

When reporting issues or contributing improvements:
1. Specify which build step failed
2. Include relevant error messages
3. Note any deviations from the standard build environment
4. Test fixes in a clean container environment

## License

[Add your preferred license here]

---

*This project creates a minimal but functional Linux system suitable for embedded development, educational purposes, or as a base for custom Linux distributions.*
