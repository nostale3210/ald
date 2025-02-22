FROM docker.io/library/alpine:latest

COPY src/ /ald

RUN chmod +x /ald/ald && \
    ls -la /ald
