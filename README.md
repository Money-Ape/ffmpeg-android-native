export ANDROID_NDK_HOME=$HOME/.buildozer/android/platform/android-ndk-r28c

export TOOLCHAIN=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64

verify : echo $ANDROID_NDK_HOME

# Clone FFMPEG

mkdir -p ~/DEV
cd ~/DEV

git clone https://github.com/FFmpeg/FFmpeg.git
cd FFmpeg

# Verify toolchain
ls $TOOLCHAIN/bin | grep aarch64-linux-android24

## Example
aarch64-linux-android24-clang
aarch64-linux-android24-clang++

# configure FFMPEG
./configure \
    --pkg-config=false \
    --prefix=$PWD/build \
    --target-os=android \
    --arch=aarch64 \
    --cpu=armv8-a \
    --enable-cross-compile \
    --cc=$TOOLCHAIN/bin/aarch64-linux-android24-clang \
    --cxx=$TOOLCHAIN/bin/aarch64-linux-android24-clang++ \
    --disable-shared \
    --enable-static \
    --enable-ffmpeg \
    --disable-ffplay \
    --disable-ffprobe \
    --disable-doc \
    --disable-debug \
    --ar=$TOOLCHAIN/bin/llvm-ar
    --nm=$TOOLCHAIN/bin/llvm-nm
    --strip=$TOOLCHAIN/bin/llvm-strip

# Build
make -j$(nproc)

# Install
make install

## Now check
file build/bin/ffmpeg

# Deep Validation
readelf -d build/bin/ffmpeg
readelf -l build/bin/ffmpeg | grep interpreter
llvm-readobj --needed-libs build/bin/ffmpeg

## Example
ELF 64-bit LSB executable
ARM aarch64

## Once You have : 'build/bin/ffmpeg'
- Bundle it into the APK.
- Copy it to user_data_dir on first launch.
- Make it executable with chmod 755.

# Veify the binary
readelf -d build/bin/ffmpeg
readelf -l build/bin/ffmpeg | grep interpreter
llvm-readobj --needed-libs build/bin/ffmpeg