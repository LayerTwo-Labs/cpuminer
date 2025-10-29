#!/bin/bash
# Script to build cpuminer binaries for multiple platforms
# Uses Docker for cross-compilation on Linux/Windows
# Uses native build on macOS (no SDK needed)

# Don't use set -e globally - we want to handle errors per-platform
set +e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${SCRIPT_DIR}/binaries"
DOCKERFILE="${SCRIPT_DIR}/Dockerfile.crossbuild"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Detect if running on macOS
IS_MACOS=false
if [[ "$OSTYPE" == "darwin"* ]]; then
    IS_MACOS=true
fi

echo -e "${GREEN}Building cpuminer binaries for multiple platforms...${NC}"
if [ "$IS_MACOS" = true ]; then
    echo -e "${BLUE}Running on macOS - will build macOS binaries natively (no SDK needed)${NC}"
fi

# Create output directory
mkdir -p "${OUTPUT_DIR}"

# Build all platforms
echo -e "${YELLOW}Building Linux x86_64...${NC}"
docker build -f "${DOCKERFILE}" --target linux-x86_64 -t cpuminer-linux-x86_64 . && \
docker create --name cpuminer-linux-x86_64 cpuminer-linux-x86_64 && \
docker cp cpuminer-linux-x86_64:/build/output/minerd-linux-x86_64 "${OUTPUT_DIR}/" && \
docker rm cpuminer-linux-x86_64

echo -e "${YELLOW}Building Linux i686...${NC}"
docker build -f "${DOCKERFILE}" --target linux-i686 -t cpuminer-linux-i686 . && \
docker create --name cpuminer-linux-i686 cpuminer-linux-i686 && \
docker cp cpuminer-linux-i686:/build/output/minerd-linux-i686 "${OUTPUT_DIR}/" && \
docker rm cpuminer-linux-i686

echo -e "${YELLOW}Building Windows x86_64...${NC}"
docker build -f "${DOCKERFILE}" --target windows-x86_64 -t cpuminer-windows-x86_64 . && \
docker create --name cpuminer-windows-x86_64 cpuminer-windows-x86_64 && \
docker cp cpuminer-windows-x86_64:/build/output/minerd-windows-x86_64.exe "${OUTPUT_DIR}/" && \
docker rm cpuminer-windows-x86_64

echo -e "${YELLOW}Building Windows i686...${NC}"
docker build -f "${DOCKERFILE}" --target windows-i686 -t cpuminer-windows-i686 . && \
docker create --name cpuminer-windows-i686 cpuminer-windows-i686 && \
docker cp cpuminer-windows-i686:/build/output/minerd-windows-i686.exe "${OUTPUT_DIR}/" && \
docker rm cpuminer-windows-i686

# Build macOS binaries
if [ "$IS_MACOS" = true ]; then
    # Build natively on macOS - no SDK needed, it's already available
    # Check and install dependencies if needed
    if ! command -v autoconf >/dev/null 2>&1 || ! command -v automake >/dev/null 2>&1; then
        echo -e "${YELLOW}Installing build dependencies...${NC}"
        brew install autoconf automake libtool pkg-config curl 2>/dev/null || true
    fi
    
    echo -e "${YELLOW}Building macOS x86_64 (native build, no SDK needed)...${NC}"
    ./autogen.sh && \
    ./configure CFLAGS="-O3" --host=x86_64-apple-darwin && \
    make clean && \
    make -j$(sysctl -n hw.ncpu 2>/dev/null || echo "4")
    if [ $? -eq 0 ] && [ -f minerd ]; then
        cp minerd "${OUTPUT_DIR}/minerd-macos-x86_64"
        echo -e "${GREEN}macOS x86_64 build successful${NC}"
        make clean || true
    else
        echo -e "${RED}macOS x86_64 build failed${NC}"
    fi

    echo -e "${YELLOW}Building macOS arm64 (native build, no SDK needed)...${NC}"
    ./autogen.sh && \
    ./configure CFLAGS="-O3 -arch arm64" --host=arm64-apple-darwin && \
    make clean && \
    make -j$(sysctl -n hw.ncpu 2>/dev/null || echo "4")
    if [ $? -eq 0 ] && [ -f minerd ]; then
        cp minerd "${OUTPUT_DIR}/minerd-macos-arm64"
        echo -e "${GREEN}macOS arm64 build successful${NC}"
        make clean || true
    else
        echo -e "${RED}macOS arm64 build failed${NC}"
    fi
else
    # Cross-compile from Linux using Docker - SDK needed if available
    echo -e "${YELLOW}Building macOS x86_64 (Docker cross-compile - SDK optional)...${NC}"
    if docker build -f "${DOCKERFILE}" --target macos-x86_64 -t cpuminer-macos-x86_64 .; then
        docker create --name cpuminer-macos-x86_64 cpuminer-macos-x86_64
        if docker cp cpuminer-macos-x86_64:/build/output/minerd-macos-x86_64 "${OUTPUT_DIR}/" 2>/dev/null; then
            echo -e "${GREEN}macOS x86_64 build successful${NC}"
        else
            echo -e "${YELLOW}macOS x86_64 build skipped (macOS SDK not provided - install Xcode on macOS to extract SDK)${NC}"
        fi
        docker rm cpuminer-macos-x86_64
    else
        echo -e "${YELLOW}macOS x86_64 build skipped (macOS SDK not provided)${NC}"
    fi

    echo -e "${YELLOW}Building macOS arm64 (Docker cross-compile - SDK optional)...${NC}"
    if docker build -f "${DOCKERFILE}" --target macos-arm64 -t cpuminer-macos-arm64 .; then
        docker create --name cpuminer-macos-arm64 cpuminer-macos-arm64
        if docker cp cpuminer-macos-arm64:/build/output/minerd-macos-arm64 "${OUTPUT_DIR}/" 2>/dev/null; then
            echo -e "${GREEN}macOS arm64 build successful${NC}"
        else
            echo -e "${YELLOW}macOS arm64 build skipped (macOS SDK not provided - install Xcode on macOS to extract SDK)${NC}"
        fi
        docker rm cpuminer-macos-arm64
    else
        echo -e "${YELLOW}macOS arm64 build skipped (macOS SDK not provided)${NC}"
    fi
fi

echo -e "${GREEN}Build complete! Binaries are in: ${OUTPUT_DIR}${NC}"
echo ""
echo "Files created:"
ls -lh "${OUTPUT_DIR}"

# Make binaries executable
chmod +x "${OUTPUT_DIR}"/minerd-linux-* 2>/dev/null || true
chmod +x "${OUTPUT_DIR}"/minerd-macos-* 2>/dev/null || true

