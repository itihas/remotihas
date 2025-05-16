localFlake:

{ lib, config, self, inputs, withSystem, ... }: {
  flake.nixosModules.disko = { config, pkgs, ... }: {
    imports = [ inputs.disko.nixosModules.disko ];
    disko.devices = {
      disk = {
        main = {
          type = "disk";
          device = "/dev/disk/by-diskseq/1";
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                priority = 1;
                name = "ESP";
                start = "1M";
                end = "128M";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [ "umask=0077" ];
                };
              };
              root = {
                size = "100%";
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ]; # Override existing partition
                  mountpoint = "/";
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
              };
            };
          };
        };
      };
    };
  };

  flake.nixosConfigurations.remotihas = withSystem "x86_64-linux"
    ({ config, system, ... }:
      inputs.nixpkgs.lib.nixosSystem {
        modules = with self.nixosModules; [
          ({ modulesPath, ... }: {
            imports = [
              (modulesPath + "/installer/scan/not-detected.nix")
              (modulesPath + "/profiles/qemu-guest.nix")
            ];
          })
          gitit
          wireguard
          myFormats
          itihas
          disko
          inputs.nixos-facter-modules.nixosModules.facter
          ({ config, lib, pkgs, ... }: {

            networking.useDHCP = lib.mkDefault true;
            nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
            boot.loader.grub.enable = true;
            boot.loader.grub.efiSupport = true;
            boot.loader.grub.efiInstallAsRemovable = true;
            boot.loader.grub.device = "/dev/sda";
            networking.hostName = "remotihas";
            networking.fqdn = "itihas.xyz";
            networking.networkmanager.enable = true;

            services.gitit = {
              enable = true;
              nginx = {
                enable = true;
                hostName = "gitit.${config.networking.fqdn}";
              };
            };
            services.privatebin = {
              enable = true;
              enableNginx = true;
              virtualHost = "paste.${config.networking.fqdn}";
            };
            services.fail2ban.enable = true;

            services.openssh.enable = true;
            networking.firewall.allowedTCPPorts = [ 22 80 443 ];
          })
        ];
      });

}
