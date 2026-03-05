FROM golang:1.24-bookworm AS builder

ARG MATTERMOST_REPO=https://github.com/mattermost/mattermost
ARG MATTERMOST_REF=e296a314bb93a318b66aec81353776b7d95aa04a
ARG MATTERMOST_VERSION=11.5.0
ARG TARGETARCH

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        make \
        patch \
        python3 \
        g++ \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

RUN git init mattermost \
    && git -C mattermost remote add origin "${MATTERMOST_REPO}" \
    && git -C mattermost fetch --depth 1 origin "${MATTERMOST_REF}" \
    && git -C mattermost checkout --detach FETCH_HEAD

COPY patches /patches

WORKDIR /build/mattermost

RUN patch -p1 < /patches/mattermesh-sso.patch \
    && patch -p1 < /patches/mattermesh-nolimituserpatch.patch \
    && patch -p1 < /patches/mattermesh-team-buildfix.patch

# Keep server/public aligned with this exact monorepo checkout.
RUN cd /build/mattermost/server \
    && go mod edit -replace github.com/mattermost/mattermost/server/public=./public

# Force Team / non-enterprise build for the active Docker target arch.
# Explicitly use workspace mode to keep server/public and server/v8 in sync.
RUN if [ -f /build/mattermost/go.work ]; then export GOWORK=/build/mattermost/go.work; fi; \
    mkdir -p /build/mattermost/bin; \
    case "${TARGETARCH}" in \
        amd64) MM_BUILD_TARGET=build-linux-amd64 ;; \
        arm64) MM_BUILD_TARGET=build-linux-arm64 ;; \
        *) echo "Unsupported TARGETARCH=${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    make -C server BUILD_ENTERPRISE=false "${MM_BUILD_TARGET}"

# Pull prebuilt web client assets for the matching release version.
RUN case "${TARGETARCH}" in \
        amd64|arm64) MM_ARCH="${TARGETARCH}" ;; \
        *) echo "Unsupported TARGETARCH=${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    mkdir -p /build/prebuilt; \
    curl -fsSL "https://releases.mattermost.com/${MATTERMOST_VERSION}/mattermost-team-${MATTERMOST_VERSION}-linux-${MM_ARCH}.tar.gz" \
    | tar -xz -C /build/prebuilt --strip-components=1 mattermost/client


FROM debian:bookworm-slim AS runtime

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        tzdata \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --system --create-home --home /mattermost --shell /usr/sbin/nologin mattermost

WORKDIR /mattermost

RUN mkdir -p /mattermost/bin
COPY --from=builder /build/mattermost/bin/mattermost /mattermost/bin/mattermost
COPY --from=builder /build/prebuilt/client /mattermost/client
COPY --from=builder /build/mattermost/server/i18n /mattermost/i18n
COPY --from=builder /build/mattermost/server/templates /mattermost/templates
COPY --from=builder /build/mattermost/server/fonts /mattermost/fonts

RUN mkdir -p /mattermost/data /mattermost/config /mattermost/logs /mattermost/plugins /mattermost/client/plugins /mattermost/bleve-indexes \
    && chown -R mattermost:mattermost /mattermost

USER mattermost

EXPOSE 8065

CMD ["bin/mattermost", "server"]
