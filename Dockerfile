FROM debian:wheezy

# Configure apt for archived repos
RUN echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99archive && \
    echo 'Acquire::AllowInsecureRepositories "true";' >> /etc/apt/apt.conf.d/99archive && \
    echo 'deb http://archive.debian.org/debian wheezy main contrib non-free' > /etc/apt/sources.list && \
    echo 'deb http://archive.debian.org/debian-security wheezy/updates main contrib non-free' >> /etc/apt/sources.list

# Install basic tools and dependencies
RUN apt-get -o Acquire::Check-Valid-Until=false \
            -o Acquire::AllowInsecureRepositories=true \
            -o Acquire::AllowDowngradeToInsecureRepositories=true \
            --allow-unauthenticated update && \
    apt-get install -y --allow-unauthenticated \
        build-essential \
        libtool \
        autotools-dev \
        automake \
        pkg-config \
        libssl-dev \
        libevent-dev \
        bsdmainutils \
        libboost-all-dev \
        git \
        wget \
        ca-certificates \
        libqt4-dev \
        qt4-qmake \
        libminiupnpc-dev \
        zlib1g-dev \
        file \
        fuse \
        libfuse-dev || { echo "❌ Error: apt-get install failed"; exit 1; }

# Install Berkeley DB 4.8
RUN wget 'http://download.oracle.com/berkeley-db/db-4.8.30.NC.tar.gz' && \
    tar -xzf db-4.8.30.NC.tar.gz && \
    cd db-4.8.30.NC/build_unix && \
    ../dist/configure --enable-cxx --disable-shared --with-pic && \
    make && \
    make install && \
    ln -s /usr/local/BerkeleyDB.4.8/lib/libdb*.a /usr/local/lib/ || true && \
    ln -s /usr/local/BerkeleyDB.4.8/include/*.h /usr/local/include/ || true && \
    cd ../.. && \
    rm -rf db-4.8.30.NC* && \
    ldconfig

# Install linuxdeployqt for AppImage creation
RUN wget https://github.com/probonopd/linuxdeployqt/releases/download/1/linuxdeployqt-1-x86_64.AppImage && \
    chmod +x linuxdeployqt-1-x86_64.AppImage && \
    mv linuxdeployqt-1-x86_64.AppImage /usr/local/bin/linuxdeployqt

WORKDIR /linkcoin
COPY . .

# Beri izin eksekusi
RUN chmod +x ./build-linkcoin.sh

# Jalankan skrip saat container start
CMD ["/bin/bash", "/linkcoin/build-linkcoin.sh"]