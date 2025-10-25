{
  description = "Flake for building terraria server docker image";

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
      system: let
        pkgs = import nixpkgs {inherit system;};
      in rec {
        packages = {
          default = packages.docker;
          docker = pkgs.dockerTools.buildLayeredImage {
            name = "terraria-server";
            tag = "latest";
            contents = with pkgs; [
              self.nixosConfigurations.terraria-server.config.system.build.toplevel
              bashInteractive
              coreutils
            ];
            uname = "terraria";
            gname = "terraria";
            config = {
              Cmd = [ "${self.nixosConfigurations.terraria-server.config.system.build.toplevel}/init" ];
              ExposedPorts = {
                "7777/tcp" = {};
                "7777/udp" = {};
              };
              Env = [
                "PATH=/run/current-system/sw/bin"
              ];
            };
          };
        };
      }
    ) // {
      nixosConfigurations = {
        terraria-server = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            nix-tmodloader.nixosModules.tmodloader
            ({ pkgs, lib, ... }: {
              # Add the tmodloader overlay for the tmodloader-server package
              nixpkgs.overlays = [ nix-tmodloader.overlays.default ];
              # Basic system configuration
              system.stateVersion = "25.11";

              # Allow unfree packages (needed for terraria-server)
              nixpkgs.config.allowUnfree = true;

              # Enable systemd in container
              boot.isContainer = true;

              # Network configuration
              networking = {
                hostName = "terraria-server";
                firewall.enable = true;
              };

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
                  # Environment-based configuration for Docker containers
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

              # Install necessary packages
              environment.systemPackages = with pkgs; [
                coreutils
                bash
              ];

              # Container-specific optimizations
              services.openssh.enable = false;
              services.nscd.enable = false;
              system.nssModules = lib.mkForce [];

              # Minimal systemd services for container
              systemd.services."getty@".enable = false;
              systemd.services."serial-getty@".enable = false;
              systemd.services.systemd-logind.enable = false;
            })
          ];
        };
      };
    };
}

