localFlake:

{ lib, config, self, inputs, withSystem, ... }: {

  flake.nixosModules = {
    ente = { config, pkgs, lib, ... }:
      let name = "ente";
      in {
        imports = [ inputs.ente.nixosModules.ente ];
        sops.secrets."ente.yaml" = {
          format = "yaml";
          sopsFile = ./secrets/remotihas/ente.yaml;
          key = "";
          owner = name;
          group = name;
        };
        services.ente = {
          enable = true;
          nginx.enable = true;
          domain = "${name}.${config.networking.fqdn}";
          port = 6060;
          museumExtraConfig = {
            db = {
              host = "/run/postgresql";
              user = name;
              inherit name;
            };
            s3 = {
              are_local_buckets = false;
              b2-eu-cen = {
                bucket = "bucketihas";
                region = "hel1";
                endpoint = "hel1.your-objectstorage.com";
              };
            };
            credentials-file = config.sops.secrets."ente.yaml".path;
            log-file = "/var/log/ente/ente.log";
            internal = {
              admin = "1580559962386439";
              disable-registration = true;
            };
          };
        };

        services.postgresql = {
          enable = true;
          ensureUsers = [{
            name = name;
            ensureDBOwnership = true;
            ensureClauses.login = true;
          }];
          ensureDatabases = [ name ];
        };
      };
  };
}
