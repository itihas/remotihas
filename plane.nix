localFlake:

{ lib, config, self, inputs, withSystem, ... }: {
  perSystem = { config, self', pkgs, ... }: {
    packages.plane-compose = let version = "v0.27.1";
    in pkgs.linkFarm "plane-compose" {
      "variables.env" = pkgs.fetchurl {
        url =
          "https://github.com/makeplane/plane/releases/download/${version}/variables.env";
        hash =
          "sha256:04d7881853aec657e6b053f7db972ec28b7ccf653322fb3334fb9e1ccfe8cb5e";
      };
      "docker-compose.yml" = pkgs.fetchurl {
        url =
          "https://github.com/makeplane/plane/releases/download/${version}/docker-compose.yml";
        hash =
          "sha256:857417155fe61f1c2516517cf7000a59e702bee8fbc2192ceafbc57d70098925";
      };
    };
  };
  flake.nixosModules.plane = { config, pkgs, ... }: {
    imports = [ self.nixosModules.docker ];
    systemd.services.plane = {
      wantedBy = [ "multi-user.target" ];
      environment = {
        NGINX_PORT = "2030";
        APP_DOMAIN = "plane.${config.networking.fqdn}";
        WEB_URL = "https://plane.${config.networking.fqdn}";        
      };
      serviceConfig = {
        ExecStart = "${pkgs.docker}/bin/docker compose -f ${
            self.packages.${pkgs.stdenv.hostPlatform.system}.plane-compose
          }/docker-compose.yml up";
      };
    };

    services.nginx.virtualHosts."plane.${config.networking.fqdn}" = {
      forceSSL = true;
      enableACME = true;
      locations."/".proxyPass = "http://127.0.0.1:2030/";
    };
  };
}

