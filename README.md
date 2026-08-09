# ⚙️ FFmpeg Android Native

Build **native FFmpeg binaries for Android (aarch64, x86, x86_64)** using Android NDK (LLVM toolchain).

This repository provides a **fully automated pipeline** to:

- Compile FFmpeg for Android
- Generate a portable static binary
- Verify binary integrity and dependencies
- Supports multiple architectures (aarch64, x86, x86_64)

---

## 🧰 Requirements

- Linux (Arch / Ubuntu / etc.)
- Python 3
- Android NDK (provided via Buildozer)

---

## 📦 Why Buildozer?

This project **does NOT use Buildozer to build APKs**, but it **reuses the Android NDK installed by Buildozer**.

👉 Reason:
- Buildozer automatically installs a working Android SDK + NDK
- Avoids manual NDK setup complexity
- Ensures compatibility with python-for-android projects

---

## ⚙️ Install Buildozer (Required for NDK)

## Arch Linux
```bash
sudo pacman -S python git zip unzip openjdk-17-jdk
python -m venv venv
source venv/bin/activate
pip install --upgrade buildozer cython
```

## Debian / Ubuntu
```bash
sudo apt update
sudo apt install -y python3 python3-pip git zip unzip openjdk-17-jdk \
    autoconf libtool pkg-config zlib1g-dev libncurses5-dev \
    libncursesw5-dev libtinfo5 cmake libffi-dev libssl-dev

python3 -m venv venv
source venv/bin/activate
pip3 install --upgrade buildozer cython
```

- Debian/Ubuntu need **build dependencies explicitly installed**
- These are required for:
  - compiling Python modules
  - building native dependencies (like FFmpeg)

---

## 📥 Initialize Buildozer (NDK Setup)

- make sure venv is activated.!
### Run once:
```bash
buildozer -v android debug
```
- This will download: `~/.buildozer/android/platform/android-ndk-r28c`

---

## 📦 Environment Setup

This repo uses Buildozer's NDK:

```bash
export ANDROID_NDK_HOME=$HOME/.buildozer/android/platform/android-ndk-r28c
export TOOLCHAIN=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64
```

Or simply run:

```bash
source ./env.sh
```

---

## 🚀 Build FFmpeg

```bash
chmod +x *.sh
./build.sh [aarch64 | x86 | x86_64]
```

## Example (Select Architecture)
```bash
You can choose which Android architecture to build:

```bash
./build.sh aarch64   # Real devices (recommended)
./build.sh x86       # (32-bit)
./build.sh x86_64    # (64-bit)
```

What happens internally:

- Clones FFmpeg (if not already present)
- Cleans previous builds
- Configures for Android ARM64, x86,x86_64 architectures
- Compiles using LLVM toolchain
- Outputs binary to:

```
output/
├── ffmpeg-aarch64
├── ffmpeg-x86
└── ffmpeg-x86_64
```

Key build config:

```
--arch=aarch64
--target-os=android
--enable-static
--disable-shared
```

LLVM tools used:

```
--ar=llvm-ar
--nm=llvm-nm
--strip=llvm-strip
```

---

## ✅ Verify Build

```bash
./verify.sh
```

This checks:

- Binary format
- Linked dependencies
- ELF interpreter
- Required libraries

Core checks:

```bash
file output/ffmpeg-<arch> # Example: file output/ffmpeg-x86_64
readelf -d output/ffmpeg
readelf -l output/ffmpeg | grep interpreter
llvm-readobj --needed-libs output/ffmpeg
```

---

## 📂 Output

```
output/ffmpeg
```

Expected:

```yaml
aarch64  → ELF 64-bit ARM
x86      → ELF 32-bit Intel 80386
x86_64   → ELF 64-bit x86-64
```

---

## Android Integration

After building:

### 1. Bundle into APK

Place binary in:

```
assets/ffmpeg
```

### 2. On first app launch

- Copy to `user_data_dir`
- Make executable:

```bash
chmod 755 ffmpeg
```

### 3. Use with yt-dlp

```python
ffmpeg_location = "/path/to/ffmpeg"
```

---

## Build Type

This repo produces:

- ✅ Static FFmpeg binary
- ✅ No external shared dependencies
- ✅ Portable across Android devices (multi-arch support)

---

## ⚠️ Notes

- Uses modern LLVM toolchain (NDK r23+)
- Does NOT use deprecated `--cross-prefix`
- Compatible with python-for-android workflows

---

## Debugging

If build fails:

```bash
make clean
make distclean
```

Re-run:

```bash
./build.sh <arch>
```

---

## Summary

```bash
source ./env.sh
./build.sh <arch>
./verify.sh
```

---

## ✅ Status

✔ FFmpeg builds successfully
✔ ARM64 binary generated
✔ Verified with ELF tools
✔ Ready for Android packaging

---

## Future Improvements

- Reduce binary size (~20MB → ~5MB)
- Add codec selection (H264, AAC only)
- Multi-arch builds (armv7 + arm64, x86, x86_64)
- GitHub Actions auto-build

---

## 🧠 Architecture Notes

- **aarch64 (ARM64)** → Required for real Android devices
- **x86 / x86_64** → Used for emulators (AVD, Genymotion)

👉 For production builds, only `aarch64` is needed.