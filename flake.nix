{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; }
    ({ self, withSystem, ... }:
      let
        inherit (inputs.flake-parts.lib) importApply;
        mkFlakeModules = {
          gitit = importApply ./gitit.nix { inherit withSystem; };
          archivebox = importApply ./archivebox.nix { inherit withSystem; };
          caldav = importApply ./caldav.nix { inherit withSystem; };
          wireguard = importApply ./wireguard.nix { inherit withSystem; };
          calibre-web = importApply ./calibre-web.nix { inherit withSystem; };
        };
      in {
        imports = [
          inputs.flake-parts.flakeModules.flakeModules
          mkFlakeModules.gitit
          mkFlakeModules.wireguard
        ];
        systems = [ "x86_64-linux" ];
        flake.nixosModules.myFormats = { config, ... }: {
          imports = [ inputs.nixos-generators.nixosModules.all-formats ];
          nixpkgs.hostPlatform = "x86_64-linux";

          formatConfigs.vm-nogui = { config, ... }: {
            services.openssh = {
              enable = true;
              settings = {
                PermitRootLogin = "yes";
                PermitEmptyPasswords = "yes";
              };
            };

            security.pam.services.sshd.allowNullPassword = true;

            virtualisation.forwardPorts = [
              {
                from = "host";
                host.port = 2000;
                guest.port = 22;
              }
              {
                from = "host";
                host.port = 2080;
                guest.port = 80;
              }
              {
                from = "host";
                host.port = 2443;
                guest.port = 443;
              }
            ];
            users.users.root.password = "abc";
          };
        };

        flake = { flakeModules = mkFlakeModules; };

        flake.nixosConfigurations.remotihas = withSystem "x86_64-linux"
          ({ config, system, ... }:
            inputs.nixpkgs.lib.nixosSystem {
              modules = with self.nixosModules; [
                gitit
                wireguard
                myFormats
                ({ config, lib, pkgs, ... }: {
                  nixpkgs.hostPlatform = system;
                  services.gitit = {
                    enable = true;
                    nginx = {
                      enable = true;
                      hostName = "gitit.${config.networking.hostName}";
                    };
                  };
                  services.privatebin = {
                    enable = true;
                    enableNginx = true;
                    virtualHost = "paste.${config.networking.hostName}";
                  };
                  services.fail2ban.enable = true;

                  networking.firewall.allowedTCPPorts = [ 22 80 443 ];
                })
              ];
            });
      });
}
