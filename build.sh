#!/bin/bash
set -e
source ./env.sh
API=24

echo "[+] Cloning FFmpeg..."

if [ ! -d "FFmpeg" ]; then
    git clone https://github.com/FFmpeg/FFmpeg.git
fi

cd FFmpeg
echo "[+] Cleaning old builds..."

make clean || true
make distclean || true

echo "[+] Configuring..."

./configure \
    --pkg-config=false \
    --prefix=$PWD/build \
    --target-os=android \
    --arch=aarch64 \
    --cpu=armv8-a \
    --enable-cross-compile \
    \
    --cc=$TOOLCHAIN/bin/aarch64-linux-android${API}-clang \
    --cxx=$TOOLCHAIN/bin/aarch64-linux-android${API}-clang++ \
    \
    --ar=$TOOLCHAIN/bin/llvm-ar \
    --nm=$TOOLCHAIN/bin/llvm-nm \
    --strip=$TOOLCHAIN/bin/llvm-strip \
    \
    --disable-shared \
    --enable-static \
    \
    --enable-ffmpeg \
    --disable-ffplay \
    --disable-ffprobe \
    \
    --disable-doc \
    --disable-debug

echo "[+] Building..."
make -j$(nproc)

echo "[+] Installing..."
make install

cd ..

mkdir -p output
cp FFmpeg/build/bin/ffmpeg output/

echo "[✓] Build complete: output/ffmpeg"