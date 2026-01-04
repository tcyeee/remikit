#!/bin/bash
# Fix for M1/Apple Silicon Mac where Flutter/Xcode incorrectly identifies the chip
# or fails to find an arm64 device when running from a Rosetta terminal.

echo "Running Flutter for macOS with arm64 architecture..."
arch -arm64 flutter run -d macos
