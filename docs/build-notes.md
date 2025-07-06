# Minimal System Generator - Build Notes

## Dependencies (Fedora 20)
- yum install zlib-devel

## Scripts Created
- prepare-headers ✓ (installs kernel headers to /opt/target-root/usr/include)
- build-gcc ✓ (builds GCC 4.5.2 to /opt/target-root/usr)

## Fixes Applied
- Texinfo compatibility: MAKEINFO=missing + fake makeinfo script
- Directory structure: Single target root at /opt/target-root

## Next Steps
- build-binutils
- build-glibc 
- build-kernel
- build-busybox
- build-rootfs
- tar-rootfs
- host-build-image