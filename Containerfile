FROM quay.io/fedora/fedora-minimal:latest as build

COPY move-mount-beneath /move-mount-beneath

RUN dnf install -y gcc

RUN gcc /move-mount-beneath/move-mount.c -o /mmb

FROM docker.io/library/alpine:latest as final

COPY src/ /ald
COPY --from=build /mmb /ald/mmb

RUN chmod +x /ald/ald && \
    ls -la /ald
