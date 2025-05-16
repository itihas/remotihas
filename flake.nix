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
        myFlakeModules = {
          gitit = importApply ./gitit.nix { inherit withSystem; };
          archivebox = importApply ./archivebox.nix { inherit withSystem; };
          caldav = importApply ./caldav.nix { inherit withSystem; };
          wireguard = importApply ./wireguard.nix { inherit withSystem; };
          calibre-web = importApply ./calibre-web.nix { inherit withSystem; };
          itihas = importApply ./itihas.nix { inherit withSystem; };
          remotihas = importApply ./remotihas.nix { inherit withSystem; };
        };
      in {
        imports = with myFlakeModules; [
          inputs.flake-parts.flakeModules.flakeModules
          gitit
          wireguard
          itihas
          remotihas
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
                host.port = 2022;
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
              {
                from = "host";
                host.port = 2120;
                guest.port = 58120;
              }
            ];
            users.users.root.password = "abc";
          };
        };

        flake = { flakeModules = myFlakeModules; };

      });
}
