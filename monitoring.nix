localFlake:

{ self, inputs, ... }: {
  flake.nixosModules.monitoring = { config, lib, pkgs, ... }:
    with lib; {
      services.prometheus = {
        enable = true;
        exporters = {
          nginx.enable = true;
          nginxlog.enable = true;
          node.enable = true;
          php-fpm.emable = true;
          systemd.enable = true;
          postgres.enable = true;
        };
        scrapeConfigs = let
          fn = e: {
            job_name = e;
            static_configs = singleton {
              targets = singleton "localhost:${
                  toString config.services.prometheus.exporters.${e}.port
                }";
            };
          };
          activeExporters =
            map (e: mkIf config.services.prometheus.exporters.${e}.enable)
            (attrNames config.services.exporters);
        in map fn activeExporters;
      };
      services.grafana = {
        enable = true;
        settings.server = {
          http_addr = "127.0.0.1";
          http_port = 3000;
          domain = "grafana.${config.networking.fqdn}";
        };
      };
      services.nginx.virtualHosts."grafana.${
        toString config.networking.fqdn
      }".locations."/" = {
        proxyPass =
          "http://127.0.0.1:${config.services.grafnaa.settings.server.http_port}";
        recommendedProxySettings = true;
      };
    };
}
