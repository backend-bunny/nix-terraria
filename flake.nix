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
              # Add the tmodloader overlay with version override
              nixpkgs.overlays = [
                nix-tmodloader.overlays.default
                (final: prev: {
                  tmodloader-server = prev.tmodloader-server.overrideAttrs (oldAttrs: {
                    version = "v2025.08.3.1";
                    src = pkgs.fetchurl {
                      url = "https://github.com/tModLoader/tModLoader/releases/download/v2025.08.3.1/tModLoader.zip";
                      hash = "sha256-ZgHDNc8MCFA9Gd+ZZU6yw+7tSqBiyDS+Tl0ZtNnMeHU=";
                    };
                  });
                })
              ];
              # Basic system configuration
              system.stateVersion = "25.11";

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

              # tModLoader server service using nix-tmodloader module
              services.tmodloader = {
                enable = true;
                makeAttachScripts = true;
                dataDir = "/mnt/terraria-data/tmodloader";
                servers.main = lib.mkMerge [
                  {
                    enable = true;
                    autoStart = true;
                    port = lib.mkDefault 7777;
                    players = lib.mkDefault 8;
                    password = lib.mkDefault "BottomlessHoleussy";
                    autocreate = lib.mkDefault "medium";  # small, medium, or large
                    openFirewall = true;
                    secure = true;
                    noupnp = true;
                    install = lib.mkDefault [];  # No mods by default, can be overridden
                  }
                ];
              };

              # Install necessary packages for server administration
              environment.systemPackages = with pkgs; [
                coreutils
                bash
                htop
                tmux
                vim
              ];
            })
          ];
        };
      };
    };
}

