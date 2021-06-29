FROM alpine:3.14.0 AS base



FROM base AS build

ARG TARGETARCH
ARG TARGETPLATFORM
ARG TARGETVARIANT

ENV SPEEDTEST_VERSION=1.0.0
ENV SCRIPT_EXPORTER_VERSION=v2.1.2

RUN apk add --no-cache \
  bash=5.1.4-r0 \
  ca-certificates=20191127-r5 \
  curl=7.77.0-r1 \
  tar=1.34-r0

# hadolint ignore=DL3059
RUN case "$TARGETARCH" in \
      amd64)  _arch=x86_64 ;; \
      arm/v6) _arch=arm ;; \
      arm/v7) _arch=armhf ;; \
      arm64)  _arch=aarch64 ;; \
      *)      _arch="$TARGETARCH" ;; \
    esac && \
    curl -fsSL -o /tmp/ookla-speedtest.tgz \
      https://install.speedtest.net/app/cli/ookla-speedtest-${SPEEDTEST_VERSION}-${_arch}-linux.tgz && \
    tar xvfz /tmp/ookla-speedtest.tgz -C /usr/local/bin speedtest && \
    rm -rf /tmp/ookla-speedtest.tgz

# hadolint ignore=DL3059
RUN case "$TARGETARCH" in \
      arm)    _arch=armv7 ;; \
      arm/v6) _arch=armv7 ;; \
      arm/v7) _arch=armv7 ;; \
      *)      _arch="$TARGETARCH" ;; \
    esac && \
    curl -kfsSL -o /usr/local/bin/script_exporter \
      https://github.com/ricoberger/script_exporter/releases/download/${SCRIPT_EXPORTER_VERSION}/script_exporter-linux-${_arch} && \
    chmod +x /usr/local/bin/script_exporter



FROM base AS final

RUN apk add --no-cache \
  bash=5.1.4-r0 \
  ca-certificates=20191127-r5

COPY --from=build /usr/local/bin/script_exporter /usr/local/bin
COPY --from=build /usr/local/bin/speedtest /usr/local/bin

COPY config.yaml /config.yaml
COPY speedtest-exporter.sh /usr/local/bin/speedtest-exporter.sh

EXPOSE 9469

ENTRYPOINT  [ "/usr/local/bin/script_exporter" ]
