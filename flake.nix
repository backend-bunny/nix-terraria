{
  description = "NixOS tModLoader server with KubeVirt container disk support";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix-tmodloader = {
      url = "github:andOrlando/nix-tmodloader";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    nix-tmodloader,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: rec {
        packages = {
          default = packages.kubevirt-image;
          vm-image = self.nixosConfigurations.terraria-server.config.system.build.vm;
          kubevirt-image = self.nixosConfigurations.terraria-server.config.system.build.kubevirtImage;
        };
      }
    ) // {
      nixosConfigurations = {
        terraria-server = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            nix-tmodloader.nixosModules.tmodloader
            "${nixpkgs}/nixos/modules/virtualisation/kubevirt.nix"
            ({ pkgs, lib, ... }: {
              # Add the tmodloader overlay for the tmodloader-server package
              nixpkgs.overlays = [ nix-tmodloader.overlays.default ];
              # Basic system configuration
              system.stateVersion = "24.05";

              # Allow unfree packages (needed for terraria-server)
              nixpkgs.config.allowUnfree = true;

              # Boot configuration for KubeVirt (already configured by the module)
              # The KubeVirt module handles most of the configuration automatically

              # Enable SSH for remote administration
              services.openssh = {
                enable = true;
                settings = {
                  PasswordAuthentication = false;
                  PermitRootLogin = "no";
                };
              };

              # Create a user for server administration
              users.users.admin = {
                isNormalUser = true;
                extraGroups = [ "wheel" ];
                openssh.authorizedKeys.keys = [
                  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGwZajpAW5F8WCM3yGZymYVznBtaiJcnBNz7IMAfUHZM sara@wsl-general-tso"
                ];
              };

              # Network configuration for KubeVirt
              networking = {
                hostName = "terraria-server";
                firewall = {
                  enable = true;
                  allowedTCPPorts = [ 22 7777 ]; # SSH
                  allowedUDPPorts = [ 7777 ]; # Terraria default port
                };
                # Use DHCP for dynamic networking
                useDHCP = true;
              };

              # KubeVirt module already enables cloud-init and other necessary services

              # tModLoader server service using nix-tmodloader module
              services.tmodloader = {
                enable = true;
                makeAttachScripts = true;
                servers.main = lib.mkMerge [
                  {
                    enable = true;
                    autoStart = true;
                    port = lib.mkDefault 7777;
                    players = lib.mkDefault 8;
                    password = lib.mkDefault null;  # No password by default
                    autocreate = lib.mkDefault "medium";  # small, medium, or large
                    openFirewall = true;
                    secure = true;
                    noupnp = true;
                    install = lib.mkDefault [];  # No mods by default, can be overridden
                  }
                  # Environment-based configuration for runtime customization
                  (lib.mkIf (builtins.getEnv "TERRARIA_PORT" != "") {
                    port = lib.toInt (builtins.getEnv "TERRARIA_PORT");
                  })
                  (lib.mkIf (builtins.getEnv "TERRARIA_MAXPLAYERS" != "") {
                    players = lib.toInt (builtins.getEnv "TERRARIA_MAXPLAYERS");
                  })
                  (lib.mkIf (builtins.getEnv "TERRARIA_PASSWORD" != "") {
                    password = builtins.getEnv "TERRARIA_PASSWORD";
                  })
                  (lib.mkIf (builtins.getEnv "TERRARIA_WORLDSIZE" != "") {
                    autocreate = builtins.getEnv "TERRARIA_WORLDSIZE";
                  })
                  (lib.mkIf (builtins.getEnv "TERRARIA_MODS" != "") {
                    install = lib.pipe (builtins.getEnv "TERRARIA_MODS") [
                      (lib.splitString ",")
                      (map lib.toInt)
                    ];
                  })
                ];
              };

              # Install necessary packages for server administration
              environment.systemPackages = with pkgs; [
                coreutils
                bash
                htop
                tmux
                vim
                git
              ];
            })
          ];
        };
      };
    };
}

