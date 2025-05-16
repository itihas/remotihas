localFlake:

{ lib, config, self, inputs, withSystem, ... }: {
  flake.nixosConfigurations.remotihas = withSystem "x86_64-linux"
    ({ config, system, ... }:
      inputs.nixpkgs.lib.nixosSystem {
        modules = with self.nixosModules; [
          gitit
          wireguard
          myFormats
          itihas
          ({ config, lib, pkgs, ... }: {
            boot.isContainer = true;
            services.gitit = {
              enable = true;
              nginx = {
                enable = true;
                hostName = "gitit.${config.networking.hostName}";
              };
            };
            services.privatebin = {
              enable = true;
              enableNginx = true;
              virtualHost = "paste.${config.networking.hostName}";
            };
            services.fail2ban.enable = true;

            networking.firewall.allowedTCPPorts = [ 22 80 443 ];
          })
        ];
      });

}
