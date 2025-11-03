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
              Password: ${config.sops.placeholder."zitadel/firstPass"}
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
          SystemAPIUsers = [{
            system-user = {
              KeyData =
                "LS0tLS1CRUdJTiBQVUJMSUMgS0VZLS0tLS0KTUlJQklqQU5CZ2txaGtpRzl3MEJBUUVGQUFPQ0FROEFNSUlCQ2dLQ0FRRUE4TW1PazhsdDJFUkR5L3NGbjFidQpXc0d0djVDQ2xUQkZqQkpIYVVzdmlOb05Eb0c2L2lTcWVxcDRWdFo3QkI5MDQ3SjZQVWxDcXhoQXFzWWlHeWIxCmREV1Zad1JacDdlN09keHFoOFhBS1ZNUkZCbVo5ZldoZ0FKNWczRDNVckRxTXpzb1hUbzM0YkNYWXloUmk0UnUKU1RNUUdXV0hNRmVSZ0ROY1NYNkJGWDNCTnVvSG5ENCt3QTV1WXd3RWFYU01QTWJyYTZZaEh3WGZWYXl2ektCeAo1eG9wWjBnanJtVmVOUFJKcFkwc2VRcEtaUDRCaWsvcFptME5xQXp4eVNzUE5IMzYyTFMzRThzRG4vTHpaSFhrCmtteHlKWXdyS2NaNklpNnQxT2g2UUtyWEgwVXhwdnR4RFI2Z2F2eFB2RWlrMUZZTlFlRkM1ejlzbHU1SDE5Z2gKbVFJREFRQUIKLS0tLS1FTkQgUFVCTElDIEtFWS0tLS0tCg==";
              Memberships = [{
                MemberType = "System";
                Roles = [ "IAM_OWNER" "ORG_OWNER" "SYSTEM_OWNER" ];
              }];
            };
          }];

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
