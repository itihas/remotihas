localFlake:

{ config, pkgs, lib, ... }: {
  flake.nixosModules.outline = { config, pkgs, lib, ... }:
    let domain = "outline.${config.networking.fqdn}";
    in {
      sops.secrets."outline/oidcClientSecret" = {
        owner = config.services.outline.user;
        group = config.services.outline.group;
      };
      nixpkgs.config.allowUnfree = true;

      services.outline = {
        enable = true;
        port = 3003;
        publicUrl = "https://${domain}";
        forceHttps = false;
        storage.storageType = "local";
        oidcAuthentication =
          let baseUrl = config.services.zitadel.settings.ExternalDomain;
          in {
            authUrl = "https://${baseUrl}/oauth/v2/authorize";
            tokenUrl = "https://${baseUrl}/oauth/v2/token";
            userinfoUrl = "https://${baseUrl}/oidc/v1/userinfo";
            clientId = "347381465270549125";
            clientSecretFile =
              config.sops.secrets."outline/oidcClientSecret".path;
            scopes = [ "openid" "email" "profile" ];
          };
      };

      services.nginx.virtualHosts.${domain} = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass =
            "http://127.0.0.1:${toString config.services.outline.port}";
          proxyWebsockets = true;
        };
      };
    };
}
