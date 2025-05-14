localFlake:

{lib, config, self, inputs, ...}: {
  flake.nixosModule.caldav = {config, lib, pkgs, ...}: {
  };
}
