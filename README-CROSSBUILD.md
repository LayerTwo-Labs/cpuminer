# Cross-Compilation Build Guide

This guide explains how to build cpuminer binaries for Linux, Windows, and macOS using Docker.

## Quick Start

### Option 1: GitHub Actions (Recommended)

The easiest way to build multi-platform binaries is using GitHub Actions:

1. **Automatic builds**: Push to `main`/`master` branch and builds run automatically
2. **Release creation**: Push a tag (e.g., `v2.5.2`) to create a release with all binaries
3. **Manual trigger**: Go to Actions tab → "Build Multi-Platform Binaries" → Run workflow

See `.github/workflows/README.md` for more details.

### Option 2: Local Docker Build

Build all platforms locally using Docker:

```bash
./build-binaries.sh
```

This will build binaries for:
- **Linux x86_64** (64-bit)
- **Linux i686** (32-bit)
- **Windows x86_64** (64-bit)
- **Windows i686** (32-bit)
- **macOS x86_64** (if SDK available)
- **macOS arm64** (if SDK available)

Output will be in the `binaries/` directory.

### Alternative: Using Docker Compose

```bash
# Build specific platform
docker-compose -f docker-compose.crossbuild.yml build linux-x86_64

# Build all platforms (Linux and Windows only)
docker-compose -f docker-compose.crossbuild.yml build linux-x86_64 linux-i686 windows-x86_64 windows-i686
```

### Individual Platform Builds

You can also build specific platforms:

```bash
# Linux x86_64
docker build -f Dockerfile.crossbuild --target linux-x86_64 -t cpuminer-linux-x86_64 .

# Linux i686
docker build -f Dockerfile.crossbuild --target linux-i686 -t cpuminer-linux-i686 .

# Windows x86_64
docker build -f Dockerfile.crossbuild --target windows-x86_64 -t cpuminer-windows-x86_64 .

# Windows i686
docker build -f Dockerfile.crossbuild --target windows-i686 -t cpuminer-windows-i686 .
```

## macOS Builds

Building macOS binaries requires the macOS SDK, which is only available from Apple and must be obtained from Xcode.

### Option 1: Using osxcross with Docker (Cross-compile from Linux)

#### Step 1: Obtain the macOS SDK

**On a macOS system** (required to extract the SDK):

1. **Install Xcode** from the Mac App Store (if not already installed)
2. **Install Xcode Command Line Tools**:
   ```bash
   xcode-select --install
   ```

3. **Extract the SDK** using the provided script:
   ```bash
   ./extract-macos-sdk.sh
   ```
   
   This will create `MacOSX.sdk.tar.xz` in the project root.

   **Alternative manual method:**
   ```bash
   # Find your SDK (usually in Xcode.app)
   SDK_PATH="/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs"
   
   # Package the SDK
   cd "$SDK_PATH"
   tar -cJf ~/MacOSX.sdk.tar.xz MacOSX*.sdk
   
   # Move it to the project root
   mv ~/MacOSX.sdk.tar.xz /path/to/cpuminer/
   ```

#### Step 2: Place the SDK in the build context

The SDK file (`MacOSX.sdk.tar.xz`) can be placed in either:
- Project root: `/path/to/cpuminer/MacOSX.sdk.tar.xz`
- SDK subdirectory: `/path/to/cpuminer/sdk/MacOSX.sdk.tar.xz`

**Important:** The SDK file is large (~400MB+) and should NOT be committed to git. It's already in `.gitignore`.

#### Step 3: Build macOS binaries

Once the SDK file is in place, build as normal:

```bash
./build-binaries.sh
```

Or build specific macOS targets:

```bash
docker build -f Dockerfile.crossbuild --target macos-x86_64 -t cpuminer-macos-x86_64 .
docker build -f Dockerfile.crossbuild --target macos-arm64 -t cpuminer-macos-arm64 .
```

The Dockerfile will automatically:
1. Detect the SDK file in the build context
2. Set up osxcross with the SDK
3. Build the macOS binaries

### Option 2: Build on macOS (Recommended for macOS)

If you have access to a macOS system, building natively is simpler:

```bash
./autogen.sh
./configure CFLAGS="-O3"
make
```

This will create a native macOS binary.

### Troubleshooting macOS Builds

**Problem:** "macOS SDK not found" or "compiler not found"

**Solution:**
- Ensure `MacOSX.sdk.tar.xz` is in the project root or `sdk/` directory
- Verify the SDK file is not corrupted (check file size, should be ~400MB+)
- Make sure Docker has access to the build context (SDK file should be copied)

**Problem:** osxcross build fails

**Solution:**
- Check that the SDK file is properly packaged (should be a tar.xz file)
- Try using the `extract-macos-sdk.sh` script if you created it manually
- Ensure you're using a compatible macOS SDK version (10.13+ recommended)

## Dependencies

The Dockerfile installs all necessary dependencies:
- **Linux**: Native GCC toolchain
- **Windows**: mingw-w64 cross-compilation toolchain
- **macOS**: osxcross (requires macOS SDK)

## Output Files

After building, binaries will be located in:

```
binaries/
├── minerd-linux-x86_64      # Linux 64-bit
├── minerd-linux-i686        # Linux 32-bit
├── minerd-windows-x86_64.exe # Windows 64-bit
└── minerd-windows-i686.exe   # Windows 32-bit
```

## Notes

- **Windows builds**: Use MinGW-w64 for cross-compilation. The binaries are statically linked where possible.
- **macOS builds**: Require the macOS SDK from Apple. Building macOS binaries on Linux without the SDK is not possible due to licensing and technical constraints.
- **Performance**: The `-O3` optimization flag is used for all builds, providing maximum performance.

## Troubleshooting

### Windows Build Fails

If Windows builds fail with missing libcurl:
- Ensure mingw-w64 packages are installed in the Docker image
- Check that `LIBCURL="-lcurldll"` is being passed correctly

### macOS Build Fails

This is expected if you don't have the macOS SDK. To build macOS binaries:
1. Get access to a macOS system with Xcode
2. Build natively on macOS
3. Or set up osxcross with the macOS SDK (see above)

### Permission Issues

If Linux binaries are not executable:
```bash
chmod +x binaries/minerd-linux-*
```

