#!/bin/bash

BIN=output/ffmpeg

echo "[+] Checking binary..."
file $BIN

echo "[+] Checking dependencies..."
readelf -d $BIN

echo "[+] Checking interpreter..."
readelf -l $BIN | grep interpreter

echo "[+] Needed libs..."
llvm-readobj --needed-libs $BIN

echo "[✓] Verification complete"