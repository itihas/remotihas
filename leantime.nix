localFlake:

{ lib, config, self, inputs, ... }:

{
  flake.nixosModules.leantime = let cfg = config.services.leantime;
  in {
    imports = [ self.nixosModules.docker ];
    options.services.leantime = with lib; {
      enable = mkEnableOption "enable leantime";
      port = mkOption {
        type = types.int;
        default = 1234;
      };
      nginx = mkOption {
        default = { };
        description = "Configuration for nginx reverse proxy";
        type = types.submodule {
          options = {
            enable = mkOption {
              type = types.bool;
              default = false;
              description = ''
                Configure the nginx reverse proxy settings.
              '';
            };

            hostName = mkOption {
              type = types.str;
              description = ''
                The hostname used to setup the virtualhost configuration
              '';
            };
          };
        };
      };
    };

    config = with lib;
      mkMerge [
        (mkIf cfg.enable {
          virtualisation.arion.projects = {
            "leantime" = {
              name = "leantime";
              services = {
                leantime_db.service = {
                  image = "mysql:8.4";
                  container_name = "mysql_leantime";
                  volumes = { db_data = /var/lib/mysql; };
                  restart = "unless-stopped";
                  env_file = ./leantime-env;
                  networks = [ "leantime-net" ];
                  command =
                    "--character-set-server=UTF8MB4 --collation-server=UTF8MB4_unicode_ci";
                  healthcheck = {
                    test = [ "CMD" "mysqladmin" "ping" "-h" "localhost" ];
                    interval = "30 s";
                    timeout = "10 s";
                    retries = 3;
                  };

                };
                leantime.service = {
                  image = "leantime/leantime:latest";
                  restart = "unless-stopped";
                  env_file = ./leantime-env;
                  security_opt = { no-new-privileges = true; };
                  cap_add = [
                    # - CAP_NET_BIND_SERVICE
                    "CAP_CHOWN"
                    "CAP_SETGID"
                    "CAP_SETUID"
                  ];
                  ports = [ "${cfg.services.leantime.port}:8080" ];
                  networks = [ "leantime-net" ];
                  volumes = {
                    public_userfiles = "/var/www/html/public/userfiles";
                    userfiles = "/var/www/html/userfiles";
                    plugins = "/var/www/html/app/Plugins";
                    logs = "/var/www/html/storage/logs";
                  };
                  depends_on.leantime_db.condition = "service_healthy";
                };

                mysql_helper.services = {
                  image = "mysql:8.4";
                  command = "chown -R mysql:mysql /var/lib/mysql";
                  volumes = { db_data = "/var/lib/mysql"; };
                  user = "root";
                  profiles = [ "helper" ];
                };
              };
              networks.leantime-net = { };
              docker-compose.volumes = {
                db_data = { };
                userfiles = { };
                public_userfiles = { };
                plugins = { };
                logs = { };
              };
            };
          };
        })
        (mkIf cfg.nginx.enable {
          services.nginx = {
            enable = true;
            virtualHosts."${cfg.nginx.hostName}" = {
              enableACME = true;
              locations."/".proxyPass =
                "http://127.0.0.1:${builtins.toString cfg.port}/";
            };
          };
        })
      ];
  };
}
