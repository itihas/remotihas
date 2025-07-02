localFlake:

{ lib, config, self, inputs, ... }:

{
  flake.nixosModules.docker = {
    virtualisation.docker = {
      enable = true;
      storageDriver = "btrfs";
    };

    virtualisation.arion = { backend = "docker"; };
  };
}
