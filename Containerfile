FROM quay.io/fedora/fedora:latest

RUN dnf install -y git-core glibc-static gettext gettext-devel \
        autoconf flex bison libtool automake wget

RUN git clone git://git.kernel.org/pub/scm/utils/util-linux/util-linux.git && \
    cd util-linux && \
    git checkout "$(git branch -a | tail -n1 | cut -d'/' -f2-)"

RUN mkdir -p /ald

RUN cd util-linux && \
    mkdir -p out && \
    export CFLAGS="-static" && \
    export LDFLAGS='--static' && \
    env CFLAGS="$CFLAGS -g -O2 -Os -ffunction-sections -fdata-sections" ./autogen.sh && \
    env CFLAGS="$CFLAGS -g -O2 -Os -ffunction-sections -fdata-sections" \
        ./configure --disable-w --disable-shared LDFLAGS="$LDFLAGS -Wl,--gc-sections" \
        --disable-all-programs --enable-exch --disable-nls --disable-poman && \
    make DESTDIR=/util-linux/out install-strip && \
    mv out/usr/bin/exch /ald

RUN mkdir fclones && \
    cd fclones && \
    curl -s https://api.github.com/repos/pkolaczk/fclones/releases/latest \
        | grep "browser_download_url.*-glibc-x86_64.tar.gz" \
        | cut -d : -f 2,3 \
        | tr -d \" \
        | wget -qi - && \
    tar -xf fclones*.tar.gz && \
    cp usr/bin/fclones /ald

RUN rm -rf util-linux fclones && \
    dnf install -y busybox && \
    cp /usr/sbin/busybox /ald

COPY files/ /ald

RUN chmod +x /ald/ald && \
    /ald/exch --version && \
    /ald/fclones --version && \
    /ald/busybox --help && \
    ls -la /ald
