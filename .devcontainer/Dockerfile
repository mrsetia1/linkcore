FROM ubuntu:20.04

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libtool \
    autotools-dev \
    automake \
    pkg-config \
    bsdmainutils \
    python3 \
    libssl-dev \
    libevent-dev \
    libboost-system-dev \
    libboost-filesystem-dev \
    libboost-chrono-dev \
    libboost-test-dev \
    libboost-thread-dev \
    libdb5.3++-dev \
    libzmq3-dev \
    libqrencode-dev \
    wget \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install Berkeley DB 4.8 (required for wallet)
RUN wget http://download.oracle.com/berkeley-db/db-4.8.30.NC.tar.gz \
    && tar -xzf db-4.8.30.NC.tar.gz \
    && cd db-4.8.30.NC/build_unix \
    && ../dist/configure --enable-cxx --disable-shared --with-pic \
    && make -j$(nproc) \
    && make install \
    && cd ../.. \
    && rm -rf db-4.8.30.NC db-4.8.30.NC.tar.gz

# Create non-root user
RUN useradd -m vscode \
    && mkdir -p /home/vscode/.vscode-server /home/vscode/.vscode-server-insiders \
    && chown -R vscode:vscode /home/vscode

# Set environment variables
ENV BDB_INCLUDE_PATH="/usr/local/BerkeleyDB.4.8/include"
ENV BDB_LIB_PATH="/usr/local/BerkeleyDB.4.8/lib"

# Switch to non-root user
USER vscode
WORKDIR /workspace

# Set up entry point
ENTRYPOINT ["/bin/bash"]
