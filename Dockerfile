
ARG BASE="debian:stable"

FROM ${BASE} as common

ENV PALM_PKG_COMMON="dumb-init libpopt0 libtinfo6 libncurses6 libncursesw6 libusb-0.1-4"
ENV PALM_PKG_BUILD="build-essential autoconf autoconf-archive automake bison flex libncurses-dev libpopt-dev libtool libusb-dev pkg-config rman texinfo"

USER root

RUN apt update \
 && DEBIAN_FRONTEND=noninteractive apt install --yes --no-install-recommends ${PALM_PKG_COMMON} \
 && apt clean && rm -rf /var/lib/apt/lists/*

FROM common AS build

RUN apt update \
 && DEBIAN_FRONTEND=noninteractive apt install --yes --no-install-recommends ${PALM_PKG_BUILD} \
 && apt clean && rm -rf /var/lib/apt/lists/*

WORKDIR /build

COPY palm-sdks /opt/palmdev

COPY pilot-link /build/pilot-link
RUN cd /build/pilot-link \
 && autoreconf -fvi \
 && ./configure --prefix=/usr/local --enable-conduits --enable-libusb --with-bluez=no \
 && make -j4 \
 && make install

COPY pilrc /build/pilrc
RUN cd /build/pilrc/unix \
 && autoreconf -fvi \
 && ./configure --prefix=/usr/local \
 && make -j4 \
 && make install

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
 && CFLAGS="-w -O2 -fcommon" make \
 && make install MAKEINFO=true

COPY multilink /build/multilink
#RUN cd /build/multilink \
# && make \
# && make install

#FROM common

#COPY --from=build /usr/local /usr/local

