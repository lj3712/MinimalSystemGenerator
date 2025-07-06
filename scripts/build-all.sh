cd /usr/src
tar xfz /sources/linux-*.tar.gz
/scripts/prepare-headers.sh
tar xfz /sources/gcc-*.tar.gz
/scripts/build-gcc.sh
