#!/bin/bash

export ANDROID_NDK_HOME=$HOME/.buildozer/android/platform/android-ndk-r28c
export TOOLCHAIN=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64

echo "[✓] NDK: $ANDROID_NDK_HOME"