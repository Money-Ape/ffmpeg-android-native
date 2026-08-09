#!/bin/bash
set -e
set -o pipefail
source ./env.sh
API=24
ARCH=$1

if [ -z "$ARCH" ]; then
    echo "Usage: ./build.sh [aarch64 | x86 | x86_64]"
    exit 1
fi

# -------------------------
# ARCH CONFIGURATION
# -------------------------
case $ARCH in
    aarch64)
        TARGET=aarch64-linux-android
        CPU=armv8-a
        ;;
    x86)
        TARGET=i686-linux-android
        CPU=i686
        ;;
    x86_64)
        TARGET=x86_64-linux-android
        CPU=x86-64
        ;;
    *)
        echo "Invalid architecture: $ARCH"
        echo "Choose: aarch64 | x86 | x86_64"
        exit 1
        ;;
esac

echo "[+] Selected ARCH: $ARCH"

if [ ! -d "FFmpeg" ]; then
    echo "[+] Cloning FFmpeg..."
    git clone https://github.com/FFmpeg/FFmpeg.git
fi

cd FFmpeg

echo "[+] Cleaning old builds..."
make clean || true
make distclean || true

echo "[+] Configuring for $ARCH..."

./configure \
    --pkg-config=false \
    --prefix=$PWD/build-$ARCH \
    --target-os=android \
    --arch=$ARCH \
    --cpu=$CPU \
    --enable-cross-compile \
    \
    --cc=$TOOLCHAIN/bin/${TARGET}${API}-clang \
    --cxx=$TOOLCHAIN/bin/${TARGET}${API}-clang++ \
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
    --disable-debug \
    \
    --disable-x86asm \
    --disable-inline-asm \
    --disable-asm \
    --disable-runtime-cpudetect

echo "[+] Building..."
make -j$(nproc) 2>&1 | tee build-$ARCH.log

echo "[+] Installing..."
make install

cd ..

OUT_DIR=ffmpeg-native-bin/ffmpeg-$ARCH
LIB_DIR=$OUT_DIR/libffmpeg

echo "[+] Creating output directories..."
mkdir -p "$LIB_DIR"

echo "[+] Copying ffmpeg binary..."

cp FFmpeg/build-$ARCH/bin/ffmpeg "$OUT_DIR/ffmpeg"

# -------------------------
# CREATE .so WRAPPER (RENAMED BIN)
# -------------------------
echo "[+] Creating shared-style binary..."

cp FFmpeg/build-$ARCH/bin/ffmpeg "$LIB_DIR/libffmpegbin.so"

chmod +x "$OUT_DIR/ffmpeg"
chmod +x "$LIB_DIR/libffmpegbin.so"

# -------------------------
# DONE
# -------------------------
echo ""
echo "[✓] Build complete!"
echo " ├── Binary:        $OUT_DIR/ffmpeg"
echo " └── Shared-style:  $LIB_DIR"