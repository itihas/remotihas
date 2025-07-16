localFlake:

{ lib, config, self, inputs, withSystem, ... }: {
  perSystem = { config, self', pkgs, ... }:
    let version = "v0.27.1";
    in {
      packages.plane-compose = {
        src = pkgs.fetchurl {
          url =
            "https://github.com/makeplane/plane/releases/download/${version}/docker-compose.yml";
          hash =
            "sha256:857417155fe61f1c2516517cf7000a59e702bee8fbc2192ceafbc57d70098925";
        };
      };
    };
  flake.nixosModules.plane = { config, pkgs, ... }:
    {

    };
}

