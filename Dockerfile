
ARG BASE="debian:stable"

FROM ${BASE} as common

ENV PALM_DEPENDS="dumb-init build-essential autoconf autoconf-archive automake bison flex libncurses-dev libpopt-dev libtool libusb-dev pkg-config rman texinfo"

USER root

# Install dependencies
RUN apt update \
 && DEBIAN_FRONTEND=noninteractive apt install --yes --no-install-recommends ${PALM_DEPENDS} \
 && apt clean && rm -rf /var/lib/apt/lists/*

# Work in build directory
WORKDIR /build

# Install Palm SDKs
COPY palm-sdks /opt/palmdev

# Build and install prc-tools (the toolchain)
COPY prc-tools /build/prc-tools
RUN cd /build/prc-tools \
 && mkdir -p build \
 && cd build \
 && ../prc-tools-2.3/configure \
      --prefix=/usr/local \
      --disable-nls \
      --build=i686-linux-gnu \
      --host=i686-linux-gnu \
      --enable-targets=m68k-palmos \
      --enable-languages=c,c++ \
      --enable-install-libbfd \
      --enable-generic \
      --with-palmdev-prefix=/opt/palmdev \
 && make \
 && make install MAKEINFO=true

# Build and install pilrc
COPY pilrc /build/pilrc
RUN cd /build/pilrc/unix \
 && autoreconf -fvi \
 && ./configure --prefix=/usr/local \
 && make -j4 \
 && make install

# Build and install pilot-link
COPY pilot-link /build/pilot-link
RUN cd /build/pilot-link \
 && autoreconf -fvi \
 && ./configure --prefix=/usr/local --enable-conduits --enable-libusb --with-bluez=no \
 && make -j4 \
 && make install

# Set up pkg-config for mixed-architecture search
ENV PKG_CONFIG_PATH=/usr/local/m68k-palmos/lib/pkgconfig:/usr/local/lib/pkg-config

# Install pkg-config for Palm SDKs
RUN cd /opt/palmdev \
 && ./install.sh /usr/local

# Build and install multilink
COPY multilink /build/multilink
RUN cd /build/multilink \
 && make \
 && make install
