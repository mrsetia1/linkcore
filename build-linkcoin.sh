#!/bin/bash
set -e  # Exit jika ada error

echo "🚀 Memulai build Linkcoin..."

# Pastikan kita berada di direktori proyek
DIR="/linkcoin"
cd "$DIR"

# Cek apakah file bitcoin-qt.pro ada (karena ini proyek Qt)
if [ ! -f "bitcoin-qt.pro" ]; then
    echo "❌ Error: File bitcoin-qt.pro tidak ditemukan di $DIR"
    exit 1
fi

# Build LevelDB
echo "🔨 Membangun LevelDB..."
cd src/leveldb
make OPT="-m64 -pipe -O2" libleveldb.a libmemenv.a
if [ $? -ne 0 ]; then
    echo "❌ Error: Gagal membangun LevelDB"
    exit 1
fi
cd ../..

# Buat direktori build jika belum ada
echo "📁 Membuat direktori build..."
mkdir -p build
if [ $? -ne 0 ]; then
    echo "❌ Error: Gagal membuat direktori build"
    exit 1
fi

# Generate build.h
echo "📝 Menghasilkan build.h..."
/bin/sh share/genbuild.sh build/build.h
if [ $? -ne 0 ]; then
    echo "❌ Error: Gagal menghasilkan build.h"
    exit 1
fi

# Jalankan qmake untuk menghasilkan Makefile
echo "🔧 Menjalankan qmake..."
/usr/bin/qmake bitcoin-qt.pro
if [ $? -ne 0 ]; then
    echo "❌ Error: Gagal menjalankan qmake"
    exit 1
fi

# Cek apakah Makefile ada
if [ ! -f "Makefile" ]; then
    echo "❌ Error: Makefile tidak ditemukan di $DIR setelah menjalankan qmake"
    exit 1
fi

# Build dengan make
echo "🔨 Menjalankan make..."
make -f Makefile
if [ $? -ne 0 ]; then
    echo "❌ Error: Gagal membangun linkcoin-qt"
    exit 1
fi

echo "✅ Build selesai! Executable linkcoin-qt tersedia di $DIR"