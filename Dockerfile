FROM docker.io/library/alpine:edge as builder

RUN apk add --no-cache \
  gcc \
  make \
  wget \
  git \
  perl \
  xz-dev \
  musl-dev

ARG TARGETOS TARGETARCH VERSION=dev
COPY --from=docker.io/library/golang:1.20.2-alpine /usr/local/go/ /usr/local/go/

ENV PATH="${PATH}:/usr/local/go/bin"

WORKDIR /work

RUN git clone --recursive https://github.com/ubccr/grendel \
  && cd grendel/firmware/ipxe \
  && git checkout master \
  && git pull \
  && cd .. \
  && sed -Ei 's/make/make -j$(nproc)/g' Makefile \
  && make build \
  && make bindata \
  && cd .. \
  && go build -o grendel .

FROM docker.io/library/alpine:edge

RUN apk add --no-cache xz-libs

LABEL MAINTAINER Square Factory

WORKDIR /app

COPY --from=builder /work/grendel/grendel /app/grendel

ENTRYPOINT [ "/app/grendel" ]
CMD ["--debug", "--verbose", "serve", "-c", "/var/lib/grendel/grendel.toml", "--hosts", "/var/lib/grendel/host.json", "--images", "/var/lib/grendel/image.json", "--listen", "0.0.0.0"]
