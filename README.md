# NixOS tModLoader Server

A NixOS-based tModLoader server with automatic mod installation and management using [nix-tmodloader](https://github.com/andOrlando/nix-tmodloader).

## Features

- **KubeVirt Ready**: VM images optimized for Kubernetes/KubeVirt deployment
- **Container Disk Images**: Automatically published as container disk images for KubeVirt
- **Mod Support**: Automatic Steam Workshop mod installation
- **Server Management**: Built-in systemd service with proper logging
- **Environment Configuration**: Configurable via cloud-init and environment variables
- **SSH Key Authentication**: Secure access with SSH keys (no passwords)
- **Cloud Native**: Designed for modern container orchestration platforms

## Quick Start

### Building Images

```bash
# Using the build script (recommended)
./scripts/build-kubevirt.sh kubevirt-image  # For KubeVirt deployment
./scripts/build-kubevirt.sh vm-image        # For local testing

# Or build directly with Nix
NIXPKGS_ALLOW_UNFREE=1 nix build .#kubevirt-image --impure
NIXPKGS_ALLOW_UNFREE=1 nix build .#vm-image --impure
```

### Pre-built Container Disk Images

Pre-built KubeVirt container disk images are available on GitHub Container Registry:

```bash
# Pull the latest container disk image
docker pull ghcr.io/backend-bunny/nix-terraria-container-disk:latest

# Use in KubeVirt (see deployment section below)
```

### Local Testing with QEMU

```bash
# Start the VM locally (requires QEMU)
./result/bin/run-terraria-server-vm

# SSH access with your key
ssh admin@localhost -p 2222
```

### Server Configuration

The server can be configured through environment variables before building or at runtime:

```bash
# Example configuration
export TERRARIA_PORT=7777
export TERRARIA_MAXPLAYERS=16
export TERRARIA_PASSWORD="mypassword"
export TERRARIA_WORLDSIZE="large"  # small, medium, or large
export TERRARIA_MODS="2563851872,2815499502"  # Steam Workshop mod IDs

# Rebuild with configuration
NIXPKGS_ALLOW_UNFREE=1 nix build .#vm-image --impure
```

## Server Management

### Accessing the Server Console

```bash
# SSH into the VM
ssh admin@<vm-ip>

# Attach to the tModLoader console
sudo systemctl status tmodloader-main  # Check service status
sudo tmodloader-main-attach              # Attach to console (if available)

```

### Managing Mods

The server automatically downloads and installs Steam Workshop mods based on the `TERRARIA_MODS` environment variable:

- Set `TERRARIA_MODS` to a comma-separated list of Steam Workshop mod IDs
- Mods are downloaded during server startup
- The server automatically generates the required `enabled.json` file

### Server Administration

```bash
# View server logs
journalctl -u tmodloader-main -f

# Restart the server
sudo systemctl restart tmodloader-main

# Stop the server
sudo systemctl stop tmodloader-main

# Start the server
sudo systemctl start tmodloader-main
```

**Note**: The mod IDs are Steam Workshop IDs. For example:
- Calamity Mod: `2824688072`
- Calamity Mod Music: `2824688266`
- Boss Checklist: `2818457255`
- Recipe Browser: `2619954303`

## Network Configuration

- **Default Port**: 7777 (UDP)
- **SSH Access**: Port 22 (TCP)
- **VM Networking**: Uses DHCP (typically gets 10.0.2.15 in QEMU)

For external access, configure port forwarding:
```bash
# Example QEMU port forwarding
qemu-system-x86_64 -netdev user,id=net0,hostfwd=tcp::2222-:22,hostfwd=udp::7777-:7777 ...
```

## KubeVirt Deployment

### Prerequisites
- Kubernetes cluster with KubeVirt installed
- Container disk support enabled

### Basic Deployment

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: terraria-server
  namespace: default
spec:
  running: true
  template:
    metadata:
      labels:
        app: terraria-server
    spec:
      domain:
        devices:
          disks:
          - name: containerdisk
            disk:
              bus: virtio
          - name: cloudinitdisk
            disk:
              bus: virtio
          interfaces:
          - name: default
            bridge: {}
        resources:
          requests:
            memory: 2Gi
            cpu: 1000m
      networks:
      - name: default
        pod: {}
      volumes:
      - name: containerdisk
        containerDisk:
          image: ghcr.io/backend-bunny/nix-terraria-container-disk:latest
      - name: cloudinitdisk
        cloudInitNoCloud:
          userData: |
            #cloud-config
            users:
              - name: admin
                ssh_authorized_keys:
                  - "YOUR_SSH_PUBLIC_KEY_HERE"
                sudo: ALL=(ALL) NOPASSWD:ALL
            runcmd:
              - systemctl enable --now tmodloader-main
```

### Service Exposure

```yaml
apiVersion: v1
kind: Service
metadata:
  name: terraria-server
spec:
  selector:
    app: terraria-server
  ports:
  - name: terraria
    port: 7777
    protocol: UDP
    targetPort: 7777
  - name: ssh
    port: 22
    protocol: TCP
    targetPort: 22
  type: LoadBalancer
```

### Alternative Deployment Options

1. **Local QEMU/KVM**: Use the built VM image with libvirt or QEMU directly
2. **Cloud VMs**: Import the qcow2 image to cloud providers supporting custom images
3. **Container Platforms**: Use the container disk in any KubeVirt-compatible platform

## Mod Configuration Examples

### Popular Mod Combinations

```bash
# Calamity Mod + Quality of Life mods
export TERRARIA_MODS="2563851872,2815499502,2778832095"

# Magic Storage + Boss Checklist + Recipe Browser
export TERRARIA_MODS="2563851872,2815499502,2619954303,2824688072"
```

Find mod IDs on the [Steam Workshop](https://steamcommunity.com/app/1281930/workshop/) - they're in the URL.

## Security Notes

- **SSH Key Authentication Only**: Password authentication is disabled
- Add your SSH public key to the cloud-init configuration
- The server runs with appropriate user permissions
- Firewall is enabled by default (SSH + Terraria port only)
- Cloud-init handles initial user setup securely

## Troubleshooting

### Server Won't Start
```bash
# Check service status
sudo systemctl status tmodloader-main

# View detailed logs
journalctl -u tmodloader-main -n 50

# Check if mods are downloading
ls -la /var/lib/tmodloader/main/
```

### Network Issues
```bash
# Check firewall status
sudo ufw status

# Verify port binding
sudo netstat -tulpn | grep 7777

# Test connectivity
telnet <server-ip> 7777
```

### Performance Issues
```bash
# Monitor system resources
htop

# Check disk space
df -h

# Monitor network usage
iftop

```

## Development

This project uses:
- [NixOS](https://nixos.org/) for reproducible system configuration
- [nix-tmodloader](https://github.com/andOrlando/nix-tmodloader) for tModLoader integration
- Nix flakes for dependency management

### Development Workflow

```bash
# Edit configuration
nano flake.nix

# Test changes locally
./scripts/build-kubevirt.sh vm-image
./result/bin/run-terraria-server-vm

# Build for KubeVirt deployment
./scripts/build-kubevirt.sh kubevirt-image

# Test container disk creation
./scripts/test-container-disk.sh
```

### Available Scripts

- `scripts/build-kubevirt.sh` - Build VM or KubeVirt images
- `scripts/test-container-disk.sh` - Test container disk image creation

## Contributing

1. Fork the repository
2. Make your changes to `flake.nix`
3. Test with both VM and ISO builds
4. Submit a pull request

## License

This project is open source. Please check individual component licenses:
- Terraria/tModLoader: Re-Logic
- NixOS: MIT License
- This configuration: MIT License

## Configuration Management

### Runtime Configuration via Cloud-Init

You can configure the server at deployment time using cloud-init:

```yaml
userData: |
  #cloud-config
  write_files:
    - path: /etc/terraria-config
      content: |
        TERRARIA_PORT=7777
        TERRARIA_MAXPLAYERS=16
        TERRARIA_WORLDSIZE=large
        TERRARIA_MODS=2563851872,2815499502
  runcmd:
    - source /etc/terraria-config
    - systemctl restart tmodloader-main
```

### Build-time Configuration

Alternatively, configure at build time by setting environment variables before building:

```bash
export TERRARIA_MODS="2563851872,2815499502"
NIXPKGS_ALLOW_UNFREE=1 nix build .#kubevirt-image --impure
```

## Advanced Usage

### Connecting to the Server Console

```bash
# SSH into the VM
ssh admin@<vm-ip>

# Check service status
sudo systemctl status tmodloader-main

# View logs
sudo journalctl -u tmodloader-main -f

# Access the server console (if tmux is used)
sudo tmodloader-main-attach
```