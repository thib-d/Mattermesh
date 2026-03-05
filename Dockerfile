FROM golang:1.24-bookworm AS builder

ARG MATTERMOST_REPO=https://github.com/thib-d/mattermost
ARG MATTERMOST_REF=master

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates \
        git \
        make \
        nodejs \
        npm \
        patch \
        python3 \
        g++ \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

RUN git clone --depth 1 --branch "${MATTERMOST_REF}" "${MATTERMOST_REPO}" mattermost

COPY patches /patches

WORKDIR /build/mattermost

RUN git apply /patches/mattermesh-nolimituserpatch.patch

# Force Team / non-enterprise build.
RUN make -C server BUILD_ENTERPRISE=false build-linux


FROM debian:bookworm-slim AS runtime

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        tzdata \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --system --create-home --home /mattermost --shell /usr/sbin/nologin mattermost

WORKDIR /mattermost

COPY --from=builder /build/mattermost/server/dist/ /mattermost/

RUN mkdir -p /mattermost/data /mattermost/config /mattermost/logs /mattermost/plugins /mattermost/client/plugins /mattermost/bleve-indexes \
    && chown -R mattermost:mattermost /mattermost

USER mattermost

EXPOSE 8065

CMD ["bin/mattermost", "server"]
