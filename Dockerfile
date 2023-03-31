# ---------------------------------------------------
FROM --platform=linux/arm64/v8 docker.io/library/alpine:edge as ipxe-builder-arm64
# ---------------------------------------------------

RUN apk add --no-cache \
  gcc \
  make \
  wget \
  git \
  perl \
  xz-dev \
  musl-dev

WORKDIR /work

RUN git clone --recursive https://github.com/SquareFactory/grendel.git \
  && cd grendel/firmware/ipxe/src \
  && git checkout master \
  && git pull

RUN cd grendel/firmware/ipxe/src \
  && sed -i '/^\/\/#define VLAN_CMD/s/^\/\///' config/general.h \
  && sed -i '/^\/\/#define DIGEST_CMD/s/^\/\///' config/general.h \
  && sed -i '/^\/\/#define NSLOOKUP_CMD/s/^\/\///' config/general.h \
  && sed -i '/^\/\/#define PING_CMD/s/^\/\///' config/general.h \
  && sed -i '/^\/\/#define NTP_CMD/s/^\/\///' config/general.h \
  && sed -i '/^\/\/#define\tCONSOLE_SYSLOG/s/^\/\///' config/console.h \
  && sed -i '/^\/\/#define\tCONSOLE_SYSLOGS/s/^\/\///' config/console.h \
  && make -j$(nproc) bin-arm64-efi/ipxe.efi EMBED=../../boot.ipxe

# ---------------------------------------------------
FROM --platform=linux/amd64 docker.io/library/alpine:edge as ipxe-builder-amd64
# ---------------------------------------------------

RUN apk add --no-cache \
  gcc \
  make \
  wget \
  git \
  perl \
  xz-dev \
  musl-dev

WORKDIR /work

RUN git clone --recursive https://github.com/SquareFactory/grendel.git \
  && cd grendel/firmware/ipxe/src \
  && git checkout master \
  && git pull

RUN cd grendel/firmware/ipxe/src \
  && sed -i '/^\/\/#define VLAN_CMD/s/^\/\///' config/general.h \
  && sed -i '/^\/\/#define DIGEST_CMD/s/^\/\///' config/general.h \
  && sed -i '/^\/\/#define NSLOOKUP_CMD/s/^\/\///' config/general.h \
  && sed -i '/^\/\/#define PING_CMD/s/^\/\///' config/general.h \
  && sed -i '/^\/\/#define NTP_CMD/s/^\/\///' config/general.h \
  && sed -i '/^\/\/#define\tCONSOLE_SYSLOG/s/^\/\///' config/console.h \
  && sed -i '/^\/\/#define\tCONSOLE_SYSLOGS/s/^\/\///' config/console.h \
  && make -j$(nproc) bin/ipxe.pxe \
  bin/undionly.kpxe \
  bin-x86_64-efi/ipxe.efi \
  bin-x86_64-efi/snponly.efi \
  bin-i386-efi/ipxe.efi \
  EMBED=../../boot.ipxe

# ---------------------------------------------------
FROM docker.io/library/alpine:edge as grendel-builder
# ---------------------------------------------------

RUN apk add --no-cache \
  git

ARG TARGETOS TARGETARCH VERSION=dev
COPY --from=docker.io/library/golang:1.20.2-alpine /usr/local/go/ /usr/local/go/

ENV PATH="${PATH}:/usr/local/go/bin"

WORKDIR /work

RUN git clone https://github.com/SquareFactory/grendel.git

COPY --from=ipxe-builder-arm64 /work/grendel/firmware/ipxe/src/bin-arm64-efi/ipxe.efi /work/grendel/firmware/bin/ipxe-arm64.efi
COPY --from=ipxe-builder-amd64 /work/grendel/firmware/ipxe/src/bin/ipxe.pxe /work/grendel/firmware/bin/ipxe.pxe
COPY --from=ipxe-builder-amd64 /work/grendel/firmware/ipxe/src/bin/undionly.kpxe /work/grendel/firmware/bin/undionly.kpxe
COPY --from=ipxe-builder-amd64 /work/grendel/firmware/ipxe/src/bin-x86_64-efi/ipxe.efi /work/grendel/firmware/bin/ipxe-x86_64.efi
COPY --from=ipxe-builder-amd64 /work/grendel/firmware/ipxe/src/bin-x86_64-efi/snponly.efi /work/grendel/firmware/bin/snponly-x86_64.efi
COPY --from=ipxe-builder-amd64 /work/grendel/firmware/ipxe/src/bin-i386-efi/ipxe.efi /work/grendel/firmware/bin/ipxe-i386.efi

RUN cd grendel \
  && CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o grendel .

# ---------------------------------------------------
FROM docker.io/library/alpine:edge
# ---------------------------------------------------

RUN apk add --no-cache xz-libs ipmitool

LABEL MAINTAINER Square Factory

WORKDIR /app

COPY --from=grendel-builder /work/grendel/grendel /app/grendel

ENTRYPOINT [ "/app/grendel" ]
CMD ["--debug", "--verbose", "serve", "-c", "/var/lib/grendel/grendel.toml", "--hosts", "/var/lib/grendel/host.json", "--images", "/var/lib/grendel/image.json", "--listen", "0.0.0.0"]
