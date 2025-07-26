localFlake:

{ ... }: {

  flake.nixosModules.hedgedoc = { config, pkgs, lib, ... }: let
    name = "hedgedoc";
    in {
    sops.secrets."hedgedoc/oidcClientSecret" = {
      owner = name;
      group = name;
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

    services.hedgedoc = {
      enable = true;
      settings = {
        protocolUseSSL = true;
        allowGravatar = true;
        host = "0.0.0.0";
        domain = "md.${config.networking.fqdn}";
        urlAddPort = false;
        allowOrigin = [
          "localhost"
          "127.0.0.1"
          "https://${config.services.hedgedoc.settings.domain}"
        ];
        db = {
          username = name;
          database = name;
          # or via socket
          host = "/run/postgresql";
          dialect = "postgresql";
        };
        oauth2 = {
          providerName = "authihas";
          clientID = "330616042093084673"; # From Zitadel
          clientSecret = "$HEDGEDOC_OIDC_CLIENT_SECRET"; # Env var from sops
          scope = "openid profile email";

          # Zitadel endpoints
          baseURL = "https://auth.${config.networking.fqdn}";
          userProfileURL =
            "https://auth.${config.networking.fqdn}/oidc/v1/userinfo";
          tokenURL = "https://auth.${config.networking.fqdn}/oauth/v2/token";
          authorizationURL =
            "https://auth.${config.networking.fqdn}/oauth/v2/authorize";

          # User attribute mappings
          userProfileUsernameAttr = "preferred_username";
          userProfileDisplayNameAttr = "name";
          userProfileEmailAttr = "email";
        };
      };
      # Pass the secret as environment variable
      environmentFile = config.sops.secrets."hedgedoc/oidcClientSecret".path;
    };
    services.nginx.virtualHosts.${config.services.hedgedoc.settings.domain} = {
      forceSSL = true;
      enableACME = true;
      locations."/".proxyPass =
        "http://${toString config.services.hedgedoc.settings.host}:${
          toString config.services.hedgedoc.settings.port
        }";
      locations."/socket.io/" = {
        proxyPass =
          "http://${toString config.services.hedgedoc.settings.host}:${
            toString config.services.hedgedoc.settings.port
          }";
        proxyWebsockets = true;
        extraConfig = "proxy_ssl_server_name on;";
      };
    };

  };
}
