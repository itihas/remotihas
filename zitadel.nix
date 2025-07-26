localFlake:

{ config, pkgs, lib, ... }: {
  flake.nixosModules.zitadel = { config, pkgs, lib, ... }:
    let
      dbName = config.services.zitadel.user;
      zitadelSecretConf = {
        owner = config.services.zitadel.user;
        group = config.services.zitadel.group;
      };
    in {
      sops.secrets."zitadel/masterKey" = zitadelSecretConf;
      sops.secrets."zitadel/firstPass" = zitadelSecretConf;
      sops.secrets."zitadel/postgresPassword" = zitadelSecretConf;
      sops.secrets."postgres/password" = {
        owner = "postgres";
        group = "postgres";
      };

      sops.templates."postgresInitScript" = {
        owner = "postgres";
        group = "postgres";
        content = ''
          alter user postgres with password '${
            config.sops.placeholder."postgres/password"
          }';
        '';
      };
      sops.templates."zitadelExtraSteps.yml" = zitadelSecretConf // {
        content = ''
          FirstInstance:
            InstanceName: ${config.networking.hostName}
            Org.Human:
              UserName: admin
              FirstPassword: ${config.sops.placeholder."zitadel/firstPass"}
        '';
      };
      sops.templates."zitadelPostgresUser.yml" = zitadelSecretConf // {
        content = ''
          Database:
            postgres:
              Host: localhost
              Port: ${toString config.services.postgresql.settings.port}
              Database: zitadel
              User:
                Username: ${config.services.zitadel.user}
                Password: "${
                  config.sops.placeholder."zitadel/postgresPassword"
                }"
                SSL:
                  Mode: disable
                  RootCert:
                  Cert:
                  Key:
              Admin:
                Username: postgres
                Password: "${config.sops.placeholder."postgres/password"}"
                SSL:
                  Mode: disable
                  RootCert:
                  Cert:
                  Key:
        '';
      };

      services.zitadel = {
        enable = true;
        masterKeyFile = config.sops.secrets."zitadel/masterKey".path;
        extraStepsPaths =
          [ config.sops.templates."zitadelExtraSteps.yml".path ];
        extraSettingsPaths =
          [ config.sops.templates."zitadelPostgresUser.yml".path ];
        settings = {
          Port = 7000;
          ExternalPort = 443;
          ExternalSecure = true;
          ExternalDomain = "auth.${config.networking.fqdn}";
        };
      };
      services.postgresql = {
        enable = true;
        authentication = ''
          host            all  all  ::1/128 md5
          host            all  all  127.0.0.1/32 md5
        '';
        initialScript = config.sops.templates."postgresInitScript".path;
      };
      services.nginx.virtualHosts.${config.services.zitadel.settings.ExternalDomain} =
        {
          forceSSL = true;
          enableACME = true;
          locations."/".proxyPass = "http://127.0.0.1:${
              toString config.services.zitadel.settings.Port
            }";
        };
    };
}
