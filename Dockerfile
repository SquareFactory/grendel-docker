FROM rockylinux:latest as builder

RUN apk add --no-cache \
  gcc \
  make \
  wget \
  git \
  xz-devel \
  && dnf clean all

ARG TARGETOS TARGETARCH VERSION=dev
RUN mkdir -p /usr/local \
  && wget -q https://go.dev/dl/go1.20.2.${TARGETOS}-${TARGETARCH}.tar.gz \
  && tar -C /usr/local -xzf go1.20.2.${TARGETOS}-${TARGETARCH}.tar.gz \
  && rm -f go1.20.2.${TARGETOS}-${TARGETARCH}.tar.gz

ENV PATH="${PATH}:/usr/local/go/bin"

WORKDIR /work

RUN git clone --recursive https://github.com/ubccr/grendel \
  && cd grendel/firmware \
  && sed -Ei 's/make/make -j$(nproc)/g' Makefile \
  && make build \
  && make bindata \
  && cd .. \
  && go build -o grendel .

FROM rockylinux:latest

RUN dnf install -y xz && dnf clean all

LABEL MAINTAINER Square Factory

WORKDIR /app

COPY --from=builder /work/grendel/grendel /app/grendel

ENTRYPOINT [ "/app/grendel" ]
CMD ["--debug", "--verbose", "serve", "-c", "/var/lib/grendel/grendel.toml", "--hosts", "/var/lib/grendel/host.json", "--images", "/var/lib/grendel/image.json", "--listen", "0.0.0.0"]
