localFlake:

{ lib, config, self, inputs, ... }:

{
  flake.nixosModules.docker = {
    imports = [ inputs.arion.nixosModules.arion  ];
    virtualisation.docker = {
      enable = true;
      storageDriver = "btrfs";
    };
    virtualisation.arion = {
      backend = "docker";      
    };
  };
}
