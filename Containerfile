FROM docker.io/library/alpine:latest

COPY files/ /ald

RUN chmod +x /ald/ald && \
    ls -la /ald
