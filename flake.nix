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
        flakeModules = {
          gitit = importApply ./gitit.nix { inherit withSystem; };
          archivebox = importApply ./archivebox.nix { inherit withSystem; };
          caldav = importApply ./caldav.nix { inherit withSystem; };
          openvpn = importApply ./openvpn.nix { inherit withSystem; };
          zerobin = importApply ./zerobin.nix { inherit withSystem; };
          calibre-web = importApply ./calibre-web.nix { inherit withSystem; };
        };
      in {
        imports = [
          inputs.flake-parts.flakeModules.flakeModules
          flakeModules.gitit
        ];
        systems = [ "x86_64-linux" ];
        flake.nixosModules.myFormats = { config, ... }: {
          imports = [ inputs.nixos-generators.nixosModules.all-formats ];
          nixpkgs.hostPlatform = "x86_64-linux";
        };

        flake = { inherit flakeModules; };

        flake.nixosConfigurations.remotihas = inputs.nixpkgs.lib.nixosSystem {
          modules = [{
            services.gitit = {
              enable = true;
              nginx.enable = true;
            };
          }];
        };
      });
}
