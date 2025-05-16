localFlake:

{ lib, config, self, inputs, ... }: {

  flake.nixosModules.myFormats = { config, ... }: {
    imports = [ inputs.nixos-generators.nixosModules.all-formats ];
    nixpkgs.hostPlatform = "x86_64-linux";

    formatConfigs.vm-nogui = { config, ... }: {
      services.openssh = {
        enable = true;
        settings = {
          PermitRootLogin = "yes";
          PermitEmptyPasswords = "yes";
        };
      };

      security.pam.services.sshd.allowNullPassword = true;

      virtualisation.forwardPorts = [
        {
          from = "host";
          host.port = 2022;
          guest.port = 22;
        }
        {
          from = "host";
          host.port = 2080;
          guest.port = 80;
        }
        {
          from = "host";
          host.port = 2443;
          guest.port = 443;
        }
        {
          from = "host";
          host.port = 2120;
          guest.port = 58120;
        }
      ];
      users.users.root.password = "abc";
    };
  };
}
