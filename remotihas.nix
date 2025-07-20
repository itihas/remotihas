localFlake:

{ lib, config, self, inputs, withSystem, ... }: {
  flake.nixosModules.disko = { config, pkgs, ... }: {
    imports = [ inputs.disko.nixosModules.disko ];
    disko.devices = {
      disk = {
        main = {
          type = "disk";
          device = "/dev/sda";
          content = {
            type = "table";
            format = "msdos";
            partitions = [{
              part-type = "primary";
              fs-type = "btrfs";
              name = "root";
              bootable = true;
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ]; # Override existing partition
                mountpoint = "/";
                mountOptions = [ "compress=zstd" "noatime" ];
              };
            }];
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
          inputs.sops-nix.nixosModules.sops
          inputs.nixos-facter-modules.nixosModules.facter
          ({ config, lib, pkgs, ... }: {

            networking.useDHCP = lib.mkDefault true;
            nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
            boot.loader.grub.enable = true;
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

            services.redmine.enable = true;
            services.nginx.virtualHosts."project.${config.networking.fqdn}" = {
              forceSSL = true;
              enableACME = true;
              locations."/".proxyPass = "http://127.0.0.1:${toString config.services.redmine.port}";
            };
            services.hedgedoc = {
              enable = true;
              settings = {
                protocolUseSsl = true;
                allowGravatar = true;
                host = "0.0.0.0";
                domain = "md.${config.networking.fqdn}";
                urlAddPort = false;
                allowOrigin =
                  [ "localhost" "127.0.0.1" config.services.hedgedoc.settings.domain ];
              };
            };
            services.nginx.virtualHosts.${config.services.hedgedoc.settings.domain} =
              {
                forceSSL = true;
                enableACME = true;
                locations."/".proxyPass = "http://${toString config.services.hedgedoc.settings.host}:${
                    toString config.services.hedgedoc.settings.port
                  }";
                locations."/socket.io/" = {
                  proxyPass = "http://${toString config.services.hedgedoc.settings.host}:${
                      toString config.services.hedgedoc.settings.port
                    }";
                  proxyWebsockets = true;
                  extraConfig = "proxy_ssl_server_name on;";
                };
              };

            services.privatebin = {
              enable = true;
              enableNginx = true;
              virtualHost = "paste.${config.networking.fqdn}";
              settings = {
                main = {
                  name = "pastihas";
                  discussion = false;
                  defaultformatter = "plalib.types.intext";
                  qrcode = true;
                  template = "bootstrap-dark-page";
                };
                model.class = "Filesystem";
                model_options.dir = "/var/lib/privatebin/data";
              };
            };
            services.fail2ban.enable = true;

            security.acme = {
              acceptTerms = true;
              defaults.email = "sahiti93@gmail.com";
            };

            services.nginx = {

              # Use recommended settings
              recommendedGzipSettings = true;
              recommendedOptimisation = true;
              recommendedProxySettings = true;
              recommendedTlsSettings = true;
              sslCiphers = "AES256+EECDH:AES256+EDH:!aNULL";

              commonHttpConfig = let
                realIpsFromList = lib.strings.concatMapStringsSep "\n"
                  (x: "set_real_ip_from  ${x};");
                fileToList = x:
                  lib.strings.splitString "\n" (builtins.readFile x);
                cfipv4 = fileToList (pkgs.fetchurl {
                  url = "https://www.cloudflare.com/ips-v4";
                  sha256 =
                    "0ywy9sg7spafi3gm9q5wb59lbiq0swvf0q3iazl0maq1pj1nsb7h";
                });
                cfipv6 = fileToList (pkgs.fetchurl {
                  url = "https://www.cloudflare.com/ips-v6";
                  sha256 =
                    "1ad09hijignj6zlqvdjxv7rjj8567z357zfavv201b9vx3ikk7cy";
                });
              in ''
                ${realIpsFromList cfipv4}
                ${realIpsFromList cfipv6}
                real_ip_header CF-Connecting-IP;
              '';

              virtualHosts.${config.services.privatebin.virtualHost} = {
                forceSSL = true;
                enableACME = true;
              };

            };
            services.openssh.enable = true;
            networking.firewall.allowedTCPPorts = [ 22 80 443 ];
          })
        ];
      });

}
