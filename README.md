# ⚙️ FFmpeg Android Native

Build **native FFmpeg binaries for Android (aarch64, x86, x86_64)** using the Android NDK (LLVM toolchain).

This repository provides a pipeline to:

- Compile a static `ffmpeg` binary for Android, one architecture at a time
- Package it as an Android-native-library-style `.so` file so it can be exec'd from `nativeLibraryDir`
- Sanity-check the resulting binary with ELF tools
- Target aarch64, x86, or x86_64 per invocation

---

## 🧰 Requirements

- Linux (Arch / Ubuntu / etc.)
- Python 3 (only needed to install/run Buildozer, not used by the build itself)
- Android NDK (provided via Buildozer — see below)
- `readelf` and `llvm-readobj` on your `$PATH` (or under `$TOOLCHAIN/bin`) for `verify.sh`

---

## 📦 Why Buildozer?

This project **does NOT use Buildozer to build FFmpeg**, but it **reuses the Android NDK that Buildozer installs**.

👉 Reason:
- Buildozer automatically installs a working Android SDK + NDK
- Avoids manual NDK setup complexity
- Ensures compatibility with python-for-android projects (like the app this binary ultimately ships in)

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

- Make sure your venv is activated.
### Run once:
```bash
buildozer -v android debug
```
- This downloads the NDK to: `~/.buildozer/android/platform/android-ndk-r28c`

---

## 📦 Environment Setup

`env.sh` points at Buildozer's NDK and its LLVM toolchain:

```bash
export ANDROID_NDK_HOME=$HOME/.buildozer/android/platform/android-ndk-r28c
export TOOLCHAIN=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64
```

Source it before building:

```bash
source ./env.sh
```

`build.sh` sources this automatically (`source ./env.sh` is the first line), so you don't need to `source` it yourself before calling `build.sh` — only before running standalone toolchain commands.

---

## 🚀 Build FFmpeg

```bash
chmod +x *.sh
./build.sh [aarch64 | x86 | x86_64]
```

Build one architecture per invocation — there is no "build all archs" mode:

```bash
./build.sh aarch64   # Real devices (recommended)
./build.sh x86       # 32-bit emulators
./build.sh x86_64    # 64-bit emulators
```

### What `build.sh` actually does

1. Sources `env.sh` and resolves the NDK toolchain paths.
2. Maps your chosen arch to FFmpeg's expected `--arch`/`--cpu`/`--target` values (e.g. `aarch64` → `TARGET=aarch64-linux-android`, `CPU=armv8-a`).
3. Clones `FFmpeg/FFmpeg` if the `FFmpeg/` directory doesn't already exist (it does **not** re-clone on subsequent runs).
4. Runs `make clean && make distclean` inside `FFmpeg/` to clear any previous arch's build state.
5. Runs `./configure` against **API level 24**, using the NDK's LLVM `clang`/`clang++` as the cross-compiler and `llvm-ar` / `llvm-nm` / `llvm-strip` as the binutils, with:
   ```
   --disable-shared --enable-static
   --enable-ffmpeg --disable-ffplay --disable-ffprobe
   --disable-doc --disable-debug
   --disable-x86asm --disable-inline-asm --disable-asm --disable-runtime-cpudetect
   ```
6. Builds with `make -j$(nproc)`, teeing output to `build-<arch>.log` in the `FFmpeg/` directory.
```bash
./build.sh <arch> 2>&1 | tee build-<arch>.log
```
7. `make install`s into `FFmpeg/build-$ARCH/`.
8. Copies the compiled binary into this repo's output tree (see **Output** below) — both as a plain `ffmpeg` executable and as `libffmpegbin.so`, and `chmod +x`'s both.

---

## 📂 Output

Output is **per-architecture**, under `ffmpeg-native-bin/`, not under a flat `output/` folder:

```
ffmpeg-native-bin/
└── ffmpeg-<arch>/
    ├── ffmpeg                      # plain executable
    └── libffmpeg/
        └── libffmpegbin.so         # identical binary, renamed .so
```

For example, after `./build.sh aarch64`:

```
ffmpeg-native-bin/ffmpeg-aarch64/ffmpeg
ffmpeg-native-bin/ffmpeg-aarch64/libffmpeg/libffmpegbin.so
```

Expected ELF format per arch:

```yaml
aarch64  → ELF 64-bit ARM
x86      → ELF 32-bit Intel 80386
x86_64   → ELF 64-bit x86-64
```

**Build once per architecture you need** — running `./build.sh x86` after `./build.sh aarch64` overwrites `FFmpeg/`'s build state but writes to a separate `ffmpeg-native-bin/ffmpeg-x86/` directory, so prior archs' outputs aren't clobbered.

⚠️ If you're packaging for multiple architectures (arm64-v8a + x86 + x86_64) into one APK, make sure each arch's `libffmpegbin.so` actually comes from that arch's own `ffmpeg-native-bin/ffmpeg-<arch>/` output — copying one arch's binary into another arch's native-lib folder produces an `Exec format error` at runtime on that device.

---

## ✅ Verify Build

```bash
./verify.sh
```

What it checks:

- Binary format (`file`)
- Linked dependencies (`readelf -d`)
- ELF interpreter (`readelf -l | grep interpreter`)
- Needed libraries (`llvm-readobj --needed-libs`)

Since the build uses `--disable-shared --enable-static`, `readelf -d` and the needed-libs check should come back essentially empty — that's expected, not a failure.

---

## Android Integration

The `.so`-renamed binary isn't a packaging accident — it's required. Android's app packager only extracts files under `lib/<abi>/` that end in `.so` into the app's **`nativeLibraryDir`**, which is the one place on the device guaranteed to be executable (`assets/` and external/scoped storage are commonly mounted `noexec` on modern Android and can't run arbitrary binaries placed there).

### Bundle into the APK as a native lib, not an asset

```
lib/arm64-v8a/libffmpegbin.so   ← from ffmpeg-native-bin/ffmpeg-aarch64/libffmpeg/libffmpegbin.so
lib/x86/libffmpegbin.so         ← from ffmpeg-native-bin/ffmpeg-x86/libffmpeg/libffmpegbin.so
lib/x86_64/libffmpegbin.so      ← from ffmpeg-native-bin/ffmpeg-x86_64/libffmpeg/libffmpegbin.so
```
With python-for-android, this is typically wired up via a local recipe that copies each arch's build output into the corresponding `lib/<abi>/` slot for that arch — **not** the same binary copied into every slot (that's what produces `Exec format error` on mismatched-arch devices).

---

## Build Type

This repo produces:

- ✅ Static FFmpeg binary (`--disable-shared --enable-static`)
- ✅ No external shared dependencies
- ✅ `ffmpeg` only — no `ffplay`, no real `ffprobe`
- ✅ Portable across Android devices, one binary per architecture (not a universal/fat binary)

---

## ⚠️ Notes

- Uses the modern LLVM toolchain (Buildozer's NDK r28c)
- Does **not** use the deprecated `--cross-prefix` approach
- Compatible with python-for-android workflows
- Built with `--disable-asm`/`--disable-x86asm`/`--disable-inline-asm`/`--disable-runtime-cpudetect` — this trades some performance for build reliability across NDK/toolchain versions; revisit if you need faster encodes

---

## Debugging

If a build fails partway through:

```bash
cd FFmpeg
make clean
make distclean
cd ..
```

Re-run:

```bash
./build.sh <arch>
```

Per-arch build logs are saved at `FFmpeg/build-<arch>.log` — check there first for the actual compiler/linker error before re-running.

---

## Summary

```bash
source ./env.sh          # optional standalone — build.sh sources this itself
./build.sh <arch>        # aarch64 | x86 | x86_64, one at a time
./verify.sh               # see the path caveat above before relying on this
```

---

## ✅ Status

✔ FFmpeg (`ffmpeg`-only, no `ffprobe`/`ffplay`) builds successfully per-arch
✔ arm64 (`aarch64`) binary generated and confirmed working when packaged as `libffmpegbin.so` under `lib/<abi>/`
✔ Verified with ELF tools (once pointed at the correct output path)
✔ Ready for Android packaging, one arch at a time — mixing binaries across arch folders breaks at runtime

---

## Future Improvements

- Reduce binary size (~20MB → ~5MB)
- Add codec selection (H264, AAC only)
- Actually build a real `ffprobe` binary instead of `--disable-ffprobe` + reusing `ffmpeg` under that name
- Single invocation to build all three archs in one pass
- GitHub Actions auto-build per arch

---

## 🧠 Architecture Notes

- **aarch64 (ARM64)** → Required for real Android devices
- **x86 / x86_64** → Used for emulators (AVD, Genymotion)

👉 For production builds targeting real devices, only `aarch64` is needed — building/bundling the other archs without verifying each one's `libffmpegbin.so` is genuinely arch-correct is what causes `Exec format error` crashes on emulators or mismatched devices.

## 📦 Used In
 
The `aarch64` build from this repo is bundled as `libffmpegbin.so` in **Tubit**, a YouTube/Instagram Video Downloader app:
 
[![Tubit v1.5](https://img.shields.io/badge/Tubit-v1.5-58A6FF?style=for-the-badge&logo=android&logoColor=white)](https://github.com/Money-Ape/Tubit/releases/tag/v1.5)
 