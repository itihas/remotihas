localFlake:

{lib, config, self, inputs, ...}: {
  flake.nixosModule.archivebox = {config, lib, pkgs, ...}: {
  };
}
