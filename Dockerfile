FROM alpine:3.13 AS s6-alpine

LABEL maintainer="edwy.mandret@traydstream.com"

ARG S6_OVERLAY_RELEASE=v2.2.0.3
ENV S6_OVERLAY_RELEASE=${S6_OVERLAY_RELEASE}

ADD rootfs /

# download and copy the s6-overlay archive
ADD https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_RELEASE}/s6-overlay-amd64.tar.gz /tmp/s6-overlay-amd64.tar.gz

# --no-cache: index is updated and used on the fly but not cached locally
RUN apk --no-cache add logrotate

# extract the s6-overlay archive
RUN tar -xzf /tmp/s6-overlay-amd64.tar.gz -C / \
    && rm -f /tmp/s6-overlay-amd64.tar.gz

# start the init daemon (PID 1)
ENTRYPOINT ["/init"]
