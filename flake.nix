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
          generators = importApply ./generators.nix { inherit withSystem; };
        };
      in {
        imports = with myFlakeModules; [
          inputs.flake-parts.flakeModules.flakeModules
          gitit
          wireguard
          itihas
          remotihas
          generators
        ];
        systems = [ "x86_64-linux" ];


        flake = { flakeModules = myFlakeModules; };

      });
}
