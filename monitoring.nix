localFlake:

{ self, inputs, ... }: {
  flake.nixosModules.monitoring = { config, lib, pkgs, ... }:
    with lib;
    let exporters = [ "nginx" "nginxlog" "node" "systemd" "postgres" ];
    in {
      services.prometheus = {
        enable = true;
        exporters = genAttrs exporters (n: { enable = true; });
        scrapeConfigs = mapAttrsToList (n: v: {
          job_name = n;
          static_configs = [{ targets = [ "localhost:${toString v.port}" ]; }];
        }) (getAttrs exporters config.services.prometheus.exporters);
      };
      services.grafana = {
        enable = true;
        settings.server = {
          http_addr = "127.0.0.1";
          http_port = 3001;
          domain = "grafana.${config.networking.fqdn}";
          root_url =
            "https://${config.services.grafana.settings.server.domain}/";
        };

        settings."auth.generic_oauth" = {
          enabled = true;
          allow_sign_up = true;
          auto_login = false;
          name = "Zitadel";
          client_id = "344156754164121601";
          use_pkce = true;
          auth_url =
            "https://auth.${config.networking.fqdn}/oauth/v2/authorize";
          token_url = "https://auth.${config.networking.fqdn}/oauth/v2/token";
          api_url = "https://auth.${config.networking.fqdn}/oidc/v1/userinfo";
          scopes = "openid email";
        };
      };
      services.nginx.virtualHosts."grafana.${config.networking.fqdn}" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:${
              toString config.services.grafana.settings.server.http_port
            }";
          recommendedProxySettings = true;
        };
      };
    };
}
