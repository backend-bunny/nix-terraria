# KubeVirt Deployment Guide

## Quick Deploy

1. **Pull the container disk image:**
```bash
docker pull ghcr.io/backend-bunny/nix-terraria-container-disk:latest
```

2. **Create VM manifest (terraria-vm.yaml):**
```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: terraria-server
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
        resources:
          requests:
            memory: 2Gi
            cpu: 1000m
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
                  - "REPLACE_WITH_YOUR_SSH_PUBLIC_KEY"
                sudo: ALL=(ALL) NOPASSWD:ALL
---
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

3. **Deploy to KubeVirt:**
```bash
kubectl apply -f terraria-vm.yaml
```

4. **Connect to the server:**
```bash
# Get the external IP
kubectl get svc terraria-server

# SSH to the VM
ssh admin@<EXTERNAL-IP>

# Check tModLoader service
sudo systemctl status tmodloader-main
```

## Configuration Options

### Mod Installation
Add mods via cloud-init:
```yaml
userData: |
  #cloud-config
  write_files:
    - path: /etc/terraria-mods.conf
      content: |
        TERRARIA_MODS=2563851872,2815499502,2824688072
  runcmd:
    - source /etc/terraria-mods.conf
    - systemctl restart tmodloader-main
```

### Server Settings
Configure server parameters:
```yaml
userData: |
  #cloud-config
  write_files:
    - path: /etc/terraria-config.conf
      content: |
        TERRARIA_PORT=7777
        TERRARIA_MAXPLAYERS=16
        TERRARIA_WORLDSIZE=large
        TERRARIA_PASSWORD=your-server-password
  runcmd:
    - source /etc/terraria-config.conf
    - systemctl restart tmodloader-main
```

## Troubleshooting

### Check VM Status
```bash
kubectl get vmi
kubectl get vm
```

### Access VM Console
```bash
kubectl console terraria-server
```

### View VM Logs
```bash
kubectl logs -f virt-launcher-<pod-name>
```