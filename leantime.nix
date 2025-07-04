localFlake:

{ lib, config, self, inputs, ... }:

{
  flake.nixosModules.leantime = { config, lib, pkgs, ... }:
    let cfg = config.services.leantime;
    in {
      imports = [ self.nixosModules.docker ];
      options.services.leantime = with lib; {
        port = mkOption {
          default = 1234;
          type = types.int;
        };
        extraEnvFiles = mkOption {
          default = [];
          type = types.listOf types.str;
        };
        hostName = mkOption {
          type = types.str;
          description = ''
            The hostname used to setup the virtualhost configuration
          '';
        };
      };

      config = let
        envFile =
          pkgs.writeText "leantime.env" (builtins.readFile ./leantime.env);
      in {
        virtualisation.arion.projects."leantime".settings = {
          services = {
            leantime_db.service = {
              image = "mysql:8.4";
              container_name = "mysql_leantime";
              volumes = [ "db_data:/var/lib/mysql" ];
              restart = "unless-stopped";
              env_file =
                [ envFile.outPath ] ++ cfg.extraEnvFiles;
              networks = [ "leantime-net" ];
              command =
                "--character-set-server=UTF8MB4 --collation-server=UTF8MB4_unicode_ci";
              healthcheck = {
                test = [ "CMD" "mysqladmin" "ping" "-h" "localhost" ];
                interval = "30s";
                timeout = "10s";
                retries = 3;
              };
            };
            leantime.service = {
              image = "leantime/leantime:latest";
              restart = "unless-stopped";
              env_file =
                [ envFile.outPath ] ++ cfg.extraEnvFiles;
              # security_opt = { no-new-privileges = true; };
              capabilities = {
                CAP_NET_BIND_SERVICE = false;
                CAP_CHOWN = true;
                CAP_SETGID = true;
                CAP_SETUID = true;
              };
              ports = [ "${builtins.toString cfg.port}:8080" ];
              networks = [ "leantime-net" ];
              volumes = [
                "public_userfiles:/var/www/html/public/userfiles"
                "userfiles:/var/www/html/userfiles"
                "plugins:/var/www/html/app/Plugins"
                "logs:/var/www/html/storage/logs"
              ];
              depends_on.leantime_db.condition = "service_healthy";
            };

            # mysql_helper.service = {
            #   image = "mysql:8.4";
            #   command = "chown -R mysql:mysql /var/lib/mysql";
            #   volumes = [ "db_data:/var/lib/mysql" ];
            #   user = "root";
            #   # profiles = [ "helper" ];
            # };
          };
          networks."leantime-net" = { };
          docker-compose.volumes = {
            db_data = { };
            userfiles = { };
            public_userfiles = { };
            plugins = { };
            logs = { };
          };
        };

        services.nginx = {
          enable = true;
          virtualHosts."${cfg.hostName}" = {
            enableACME = true;
            forceSSL = true;
            locations."/".proxyPass =
              "http://127.0.0.1:${builtins.toString cfg.port}/";
          };
        };
      };
    };
}
