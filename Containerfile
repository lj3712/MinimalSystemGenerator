FROM docker.io/library/fedora:20

# Use vault archives for repos
RUN sed -i 's/mirrorlist=https:\/\/mirrors.fedoraproject.org\/.*$/#&/g' /etc/yum.repos.d/fedora.repo && \
    sed -i 's|#baseurl=http://download.example/pub/fedora/linux/releases/20/.*|baseurl=http://archives.fedoraproject.org/pub/archive/fedora/linux/releases/20/Everything/$basearch/os/|g' /etc/yum.repos.d/fedora.repo && \
    sed -i 's/mirrorlist=https:\/\/mirrors.fedoraproject.org\/.*$/#&/g' /etc/yum.repos.d/fedora-updates.repo && \
    sed -i 's|#baseurl=http://download.example/pub/fedora/linux/updates/20/.*|baseurl=http://archives.fedoraproject.org/pub/archive/fedora/linux/updates/20/$basearch/|g' /etc/yum.repos.d/fedora-updates.repo

# Install build tools and deps
RUN yum -y update && \
    yum -y install \
        tar \
        gzip \
        bzip2 \
        make \
        gcc \
        gcc-c++ \
        flex \
        bison \
        texinfo \
        gmp-devel \
        mpfr-devel \
        libmpc-devel \
        ncurses-devel \
        glibc-devel \
        glibc-static \
        perl \
        patch \
	zlib-devel \ 
	glibc-devel.i686 \
	libgcc.i686 \ 
	libstdc++-devel.i686 \
	zlib-devel.i686 \ 
        which && \
    yum clean all

WORKDIR /sources

# Copy sources into image
COPY sources/*.tar.gz /sources/
COPY sources/*.tar.bz2 /sources/

CMD ["/bin/bash"]

