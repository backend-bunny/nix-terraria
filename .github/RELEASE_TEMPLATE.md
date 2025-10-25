# Release Template

Use this template when creating GitHub releases to ensure consistent release notes.

## Release Title Format
```
v1.0.0 - Brief description of the release
```

## Release Notes Template

```markdown
## 🚀 What's New

- Brief description of new features or changes
- Another feature or improvement

## 🐛 Bug Fixes

- Fixed issue with X
- Resolved problem with Y

## 🔧 Technical Changes

- Updated dependencies
- Improved build process
- Other technical improvements

## 📦 Docker Images

Docker images for this release are automatically built and available at:

- `ghcr.io/backend-bunny/nix-terraria:1.0.0` (exact version)
- `ghcr.io/backend-bunny/nix-terraria:1.0` (major.minor)
- `ghcr.io/backend-bunny/nix-terraria:1` (major version)
- `ghcr.io/backend-bunny/nix-terraria:latest` (latest release)

## 🎮 Quick Start

```bash
docker run -d \
  --name tmodloader-server \
  -p 7777:7777/tcp \
  -p 7777:7777/udp \
  -v tmodloader-data:/var/lib/tmodloader \
  ghcr.io/backend-bunny/nix-terraria:1.0.0
```

## 🔧 Breaking Changes (if any)

- List any breaking changes here
- Migration instructions if needed

---

**Full Changelog**: https://github.com/backend-bunny/nix-terraria/compare/v0.9.0...v1.0.0
```

## Version Numbering Guidelines

- **Major (1.0.0)**: Breaking changes, significant new features
- **Minor (0.1.0)**: New features, mod updates, backward compatible changes
- **Patch (0.0.1)**: Bug fixes, small improvements, documentation updates

## Creating a Release

1. Go to the [Releases page](https://github.com/backend-bunny/nix-terraria/releases)
2. Click "Create a new release"
3. Choose or create a tag following semver (e.g., `v1.0.0`)
4. Use the release title format above
5. Fill in the release notes using the template
6. Publish the release
7. GitHub Actions will automatically build and push Docker images