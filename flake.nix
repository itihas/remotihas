{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixos-generators.url = "github:nix-community/nixos-generators";
    disko.url = "github:nix-community/disko/latest";
    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
    colmena.url = "github:zhaofengli/colmena?tag=v0.4.0";
    arion.url = "github:hercules-ci/arion";
    sops-nix.url = "github:Mic92/sops-nix";

    plane = {
      url = "github:itihas/plane/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; }
    ({ self, withSystem, ... }:
      let
        myFlakeModules = inputs.nixpkgs.lib.genAttrs [
          "gitit"
          "docker"
          "focalboard"
          "plane"
          "zitadel"
          "archivebox"
          "caldav"
          "wireguard"
          "calibre-web"
          "itihas"
          "remotihas"
          "generators"
        ] (p:
          inputs.flake-parts.lib.importApply ./${p}.nix {
            inherit withSystem;
          });
      in {
        imports = (builtins.attrValues myFlakeModules)
          ++ [ inputs.flake-parts.flakeModules.flakeModules ];
        systems = [ "x86_64-linux" ];

        flake.flakeModules = myFlakeModules;

      });
}
