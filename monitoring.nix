localFlake:

{ self, inputs, ... }: {
  flake.nixosModules.monitoring = { config, lib, pkgs, ... }:
    with lib;
    let
      exporters = [ "nginx" "nginxlog" "node" "php-fpm" "systemd" "postgres" ];
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
          http_port = 3000;
          domain = "grafana.${config.networking.fqdn}";
        };
      };
      services.nginx.virtualHosts."grafana.${config.networking.fqdn}".locations."/" =
        {
          proxyPass = "http://127.0.0.1:${
              toString config.services.grafana.settings.server.http_port
            }";
          recommendedProxySettings = true;
        };
    };
}
