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
    )
    // {
      nixosConfigurations = {
        terraria-server = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            nix-tmodloader.nixosModules.tmodloader
            "${nixpkgs}/nixos/modules/virtualisation/kubevirt.nix"
            ({
              pkgs,
              lib,
              ...
            }: {
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
                extraGroups = ["wheel"];
              };

              # Network configuration for KubeVirt
              networking = {
                hostName = "terraria-server";
                firewall = {
                  enable = true;
                  allowedTCPPorts = [22 7777]; # SSH
                  allowedUDPPorts = [7777]; # Terraria default port
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
                    autocreate = lib.mkDefault "large"; # small, medium, or large
                    openFirewall = true;
                    secure = true;
                    noupnp = true;
                    install = [
                      2669644269
                      2687866031
                      2824688072
                      2824688266
                      2824688804
                      3418805352
                      2828370879
                      3233084552
                      2836588773
                      2568214360
                      2815010161
                      2817496179
                      2979448082
                      3269610671
                      3378168037
                      3309365619
                      3258620675
                      2563851005
                      2816941454
                      2603400287
                      3400340796
                      2906406399
                      3536551483
                      2853619836
                      2843258712
                      3088232292
                      3251592253
                      2829211497
                      3199815681
                      3539794482
                      2817583109
                      3001692619
                      3374233537
                      2877850919
                      3556964159
                      3008407784
                      3329620648
                      2982195397
                      3164029586
                      3277076046
                      3361139643
                      3361303564
                      3361351961
                      3417899539
                      3453353275
                      2974503494
                      3028584450
                      3161277410
                      3458992153
                      3459129920
                      3478363753
                      2847872897
                      3070430423
                      3584387001
                      3521246622
                      3222493606
                      3578165070
                      3352461632
                      2833852432
                      2570931073
                      2815540735
                      3044249615
                      2564503881
                      3455924006
                      3485231803
                      3427152309
                      3486844948
                      2838015851
                      2563309347
                      3244873353
                      2877696929
                      2992680615
                      2627948485
                      3514371462
                      3556551426
                      2799559538
                      2866111868
                      3119712528
                      3508512103
                      2619954303
                      2785100219
                      3449149200
                      3449158983
                      2562953970
                      2832487441
                      2908170107
                      3490319147
                      3241967932
                      3310041861
                      3543514645
                      3312725122
                      2864843929
                      2782337219
                      2990396828
                      3201195744
                    ];
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
