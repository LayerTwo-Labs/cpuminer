#!/bin/bash
# Script to extract macOS SDK from Xcode for use with osxcross
# This script extracts the macOS SDK from an Xcode installation on macOS

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_FILE="${SCRIPT_DIR}/MacOSX.sdk.tar.xz"

echo "macOS SDK Extraction Script"
echo "============================"
echo ""

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "Error: This script must be run on macOS to extract the SDK"
    exit 1
fi

# Find Xcode installation
XCODE_PATH=""
if [ -d "/Applications/Xcode.app" ]; then
    XCODE_PATH="/Applications/Xcode.app"
elif [ -n "$XCODE_PATH" ]; then
    XCODE_PATH="$XCODE_PATH"
else
    echo "Error: Xcode not found in /Applications/Xcode.app"
    echo "Please install Xcode from the Mac App Store or specify the path"
    exit 1
fi

SDK_PATH="${XCODE_PATH}/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs"

# Check if SDK directory exists
if [ ! -d "$SDK_PATH" ]; then
    echo "Error: SDK path not found: $SDK_PATH"
    echo "Make sure Xcode Command Line Tools are installed:"
    echo "  xcode-select --install"
    exit 1
fi

# Find the latest macOS SDK
SDK_DIR=$(ls -1 "$SDK_PATH" | grep -E "MacOSX[0-9]+\.[0-9]+\.sdk" | sort -V | tail -1)

if [ -z "$SDK_DIR" ]; then
    echo "Error: No macOS SDK found in $SDK_PATH"
    exit 1
fi

SDK_FULL_PATH="${SDK_PATH}/${SDK_DIR}"

echo "Found macOS SDK: $SDK_DIR"
echo "Full path: $SDK_FULL_PATH"
echo ""

# Extract SDK using osxcross tools if available, otherwise use tar
if command -v gen_sdk_package_pbzx.sh >/dev/null 2>&1 || [ -f "${SCRIPT_DIR}/osxcross/tools/gen_sdk_package_pbzx.sh" ]; then
    echo "Using osxcross SDK packaging tool..."
    GEN_TOOL=""
    if command -v gen_sdk_package_pbzx.sh >/dev/null 2>&1; then
        GEN_TOOL="gen_sdk_package_pbzx.sh"
    elif [ -f "${SCRIPT_DIR}/osxcross/tools/gen_sdk_package_pbzx.sh" ]; then
        GEN_TOOL="${SCRIPT_DIR}/osxcross/tools/gen_sdk_package_pbzx.sh"
    fi
    
    if [ -n "$GEN_TOOL" ]; then
        echo "Packaging SDK using: $GEN_TOOL"
        cd "$(dirname "$SDK_FULL_PATH")"
        bash "$GEN_TOOL" "$SDK_DIR"
        # The tool should create a tar.xz file in the current directory
        PACKAGED_SDK=$(ls -1 *.tar.xz 2>/dev/null | head -1)
        if [ -n "$PACKAGED_SDK" ]; then
            mv "$PACKAGED_SDK" "$OUTPUT_FILE"
            echo "SDK packaged successfully: $OUTPUT_FILE"
        fi
    fi
else
    echo "osxcross packaging tool not found, using tar..."
    echo "Note: This may create a larger file. For best results, install osxcross tools."
    
    # Create a temporary directory
    TEMP_DIR=$(mktemp -d)
    trap "rm -rf $TEMP_DIR" EXIT
    
    echo "Creating SDK package..."
    cd "$(dirname "$SDK_FULL_PATH")"
    
    # Use tar with xz compression
    tar -cJf "$OUTPUT_FILE" "$SDK_DIR"
    
    echo "SDK packaged successfully: $OUTPUT_FILE"
fi

# Show file size
if [ -f "$OUTPUT_FILE" ]; then
    SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
    echo ""
    echo "SDK file created: $OUTPUT_FILE"
    echo "File size: $SIZE"
    echo ""
    echo "Next steps:"
    echo "1. The SDK file is ready for use"
    echo "2. Place it in the project root or sdk/ subdirectory"
    echo "3. Build with: ./build-binaries.sh"
    echo ""
    echo "Note: Make sure MacOSX.sdk.tar.xz is in .gitignore (it's a large binary)"
else
    echo "Error: Failed to create SDK package"
    exit 1
fi

