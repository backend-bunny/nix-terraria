# tModLoader Server NixOS Docker Image

This flake builds a NixOS-based Docker image for running a tModLoader (modded Terraria) server with automatic mod installation and management.

## Features

- NixOS-based tModLoader server using the [nix-tmodloader](https://github.com/andOrlando/nix-tmodloader) module
- **Automatic mod installation** from Steam Workshop
- Configurable via environment variables
- Automatic world creation and management
- Persistent world storage and mod data
- Built-in security features and UPnP disabled by default
- Tmux-based server management for administration

## Getting the Docker Image

### Pre-built Images (Recommended)

Pre-built Docker images are automatically built and published to GitHub Container Registry:

```bash
# Latest release
docker pull ghcr.io/backend-bunny/nix-terraria:latest

# Specific version (when available)
docker pull ghcr.io/backend-bunny/nix-terraria:1.0.0
docker pull ghcr.io/backend-bunny/nix-terraria:1.0    # Major.minor
docker pull ghcr.io/backend-bunny/nix-terraria:1      # Major version
```

### Building Locally

**Note**: tModLoader requires accepting unfree licenses.

```bash
NIXPKGS_ALLOW_UNFREE=1 nix build .#docker --impure
docker load < result
```

Or use the provided build script:
```bash
./build.sh
```

## Running the Container

### Basic Usage

```bash
docker run -d \
  --name tmodloader-server \
  -p 7777:7777/tcp \
  -p 7777:7777/udp \
  -v tmodloader-data:/var/lib/tmodloader \
  ghcr.io/backend-bunny/nix-terraria:latest
```

### With Configuration

```bash
docker run -d \
  --name tmodloader-server \
  -p 7777:7777/tcp \
  -p 7777:7777/udp \
  -v tmodloader-data:/var/lib/tmodloader \
  -e TERRARIA_PORT=7777 \
  -e TERRARIA_MAXPLAYERS=16 \
  -e TERRARIA_PASSWORD=secretpassword \
  -e TERRARIA_WORLDSIZE=large \
  ghcr.io/backend-bunny/nix-terraria:latest
```

### With Mods (Example: Calamity Mod)

```bash
docker run -d \
  --name tmodloader-calamity \
  -p 7777:7777/tcp \
  -p 7777:7777/udp \
  -v tmodloader-data:/var/lib/tmodloader \
  -e TERRARIA_PORT=7777 \
  -e TERRARIA_MAXPLAYERS=16 \
  -e TERRARIA_MODS="2824688072,2824688266" \
  -e TERRARIA_WORLDSIZE=large \
  ghcr.io/backend-bunny/nix-terraria:latest
```

**Note**: The mod IDs are Steam Workshop IDs. For example:
- Calamity Mod: `2824688072`
- Calamity Mod Music: `2824688266`
- Boss Checklist: `2818457255`
- Recipe Browser: `2619954303`

### Finding Steam Workshop Mod IDs

1. Go to the [Terraria Steam Workshop](https://steamcommunity.com/app/105600/workshop/)
2. Find the mod you want to install
3. Look at the URL: `https://steamcommunity.com/sharedfiles/filedetails/?id=XXXXXXXXXX`
4. The number after `id=` is the Workshop ID you need

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `TERRARIA_PORT` | `7777` | Port for the tModLoader server |
| `TERRARIA_MAXPLAYERS` | `8` | Maximum number of players (1-255) |
| `TERRARIA_PASSWORD` | `""` | Server password (leave empty for no password) |
| `TERRARIA_WORLDSIZE` | `"medium"` | Auto-created world size: `small`, `medium`, or `large` |
| `TERRARIA_MODS` | `""` | Comma-separated list of Steam Workshop mod IDs to install |

## Releases and Versioning

Docker images are automatically built and published when GitHub releases are created:

- **Semantic Versioning**: Each release creates multiple tags following semantic versioning
  - `ghcr.io/backend-bunny/nix-terraria:1.2.3` (exact version)
  - `ghcr.io/backend-bunny/nix-terraria:1.2` (major.minor)
  - `ghcr.io/backend-bunny/nix-terraria:1` (major version)
  - `ghcr.io/backend-bunny/nix-terraria:latest` (latest release)

- **Development Builds**: Pushes to main branch create development images tagged with the branch name

- **Automatic Updates**: GitHub Actions automatically builds and pushes images when releases are published

**Recommended**: Use specific version tags for production deployments for better reproducibility.

## Volumes

- `/var/lib/tmodloader` - All server data including worlds, mods, and configuration
  - `main/Worlds/` - World save files
  - `main/Mods/` - Installed mods and configuration
  - `main/steamapps/` - Steam Workshop mod downloads

## Ports

- `7777/tcp` - tModLoader server TCP port
- `7777/udp` - tModLoader server UDP port

## Server Administration

The tModLoader service runs the server in a tmux session for easy administration. You can connect to the server console from within the container:

```bash
# Access the container
docker exec -it tmodloader-server /bin/bash

# Connect to the tModLoader server console (as a user in the terraria group)
sudo -u terraria tmux -S /var/lib/tmodloader/main.sock attach

# Or use the convenience script (if makeAttachScripts is enabled)
tmodloader-main-attach

# Detach from the console (use Ctrl+b, then d)
```

This allows you to run server commands, manage players, and perform administrative tasks directly.

## Development

To test the NixOS configuration without building a Docker image:

```bash
# Build the NixOS system
nix build .#nixosConfigurations.terraria-server.config.system.build.toplevel

# Or run in a VM for testing
nixos-rebuild build-vm --flake .#terraria-server
```

## Troubleshooting

### Check logs
```bash
docker logs tmodloader-server
```

### Access container shell
```bash
docker exec -it tmodloader-server /bin/bash
```

### Check service status inside container
```bash
docker exec tmodloader-server systemctl status tmodloader-server-main.service
```

### View installed mods
```bash
# Inside the container
cat /var/lib/tmodloader/main/Mods/enabled.json
ls /var/lib/tmodloader/main/steamapps/workshop/content/1281930/
```