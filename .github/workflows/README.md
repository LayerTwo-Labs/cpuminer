# GitHub Actions Workflows

This directory contains GitHub Actions workflows for automated building and releasing of cpuminer binaries.

## Workflows

### `build-binaries.yml`

Main workflow for building multi-platform binaries using individual jobs. This workflow:

- **Triggers**: 
  - Push to main/master branches
  - Tag push (v* tags)
  - Pull requests to main/master
  - Manual dispatch

- **Builds binaries for**:
  - Linux x86_64 (64-bit)
  - Linux i686 (32-bit)
  - Windows x86_64 (64-bit)
  - Windows i686 (32-bit)
  - macOS x86_64 (64-bit, optional - may fail without SDK)
  - macOS arm64 (optional - may fail without SDK)

- **Outputs**:
  - Individual binary artifacts for each platform
  - Automatic release creation when tags are pushed
  - Checksums for all binaries
  - Combined archive (tar.gz and zip) with all binaries

### `build-binaries-matrix.yml`

Alternative workflow using GitHub Actions matrix strategy for more efficient parallel builds. This is the recommended workflow for most use cases as it:
- Builds all platforms in parallel using a matrix
- More concise and maintainable
- Better for scaling to additional platforms

### `build-pr.yml`

Lightweight workflow for pull requests that only builds Linux x86_64 to quickly verify that changes compile successfully.

## Usage

### Building Binaries

1. **Push to main/master**: Automatically builds all platforms
2. **Create a tag**: Creates a GitHub release with all binaries
   ```bash
   git tag v2.5.2
   git push origin v2.5.2
   ```
3. **Manual trigger**: Go to Actions tab → "Build Multi-Platform Binaries" → Run workflow

### Downloading Binaries

After a workflow run completes:

1. Go to the Actions tab in GitHub
2. Select the workflow run
3. Scroll down to "Artifacts"
4. Download the artifacts you need

### Release Creation

When you push a tag starting with `v` (e.g., `v2.5.2`), the workflow will:

1. Build all platform binaries
2. Create SHA256 checksums for each binary
3. Package all binaries into `.tar.gz` and `.zip` archives
4. Create a GitHub Release with:
   - The combined archives
   - Individual checksum files
   - Release notes (auto-generated from tag)

## Requirements

- Docker must be available (handled by GitHub Actions runners)
- Sufficient build time (GitHub Actions provides 2000 minutes/month for free)

## Troubleshooting

### macOS Builds Fail

This is expected if macOS SDK is not available. The workflow continues even if macOS builds fail.

### Build Timeouts

If builds timeout, consider:
- Building platforms in parallel (already done)
- Using larger runners (requires paid GitHub plan)
- Skipping macOS builds if not needed

### Windows Build Issues

Windows builds require building libcurl from source. If this fails:
- Check Docker build logs
- Verify MinGW packages are available
- The workflow includes fallback curl-config wrapper

## Customization

To customize the workflows:

1. **Change build targets**: Edit the job definitions in `build-binaries.yml`
2. **Add platforms**: Add new jobs following the existing pattern
3. **Modify release process**: Edit the `create-release` job
4. **Change retention**: Modify `retention-days` in upload-artifact steps

