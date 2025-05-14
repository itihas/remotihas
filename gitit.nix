localFlake:

{ lib, config, self, inputs, ... }:
with lib;
let
  cfg = config.services.gitit;
  mkGititConfig =
    pkgs.toINIWithGlobalSection { mkKeyValue = mkKeyValueDefault { } ":"; };
in {
  flake.nixosModule.gitit = { config, lib, pkgs, ... }: {
    options.services.gitit = {
      enable =
        mkEnableOption { description = "enable running a gitit server"; };
      package = mkOption {
        default = pkgs.gitit;
        description = "Gitit package";
      };
      nginx = mkOption {
        default = { };
        description = ''
          Configuration for nginx reverse proxy.
        '';

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
                The hostname use to setup the virtualhost configuration
              '';
            };
          };
        };
      };
      port = mkOption {
        type = types.int;
        default = 5001;
        description = "tell gitit which port to serve on.";
      };
      dataDir = mkOption {
        type = types.path;
        default = "/data/gitit/wikidata";
        description = ''
          Location where Gitit stores its data. This will be version-controlled.
          If the location doesn't exist or is empty, the service pre-start will create this location by git cloning `services.gitit.srcRepo`.
        '';
      };
      extraConfig = mkOption {
        type = types.attrs;
        default = null;
        description = "attributes to append to the gitit config.";
      };
      config = mkOption {
        default = mkGititConfig ({
          inherit (cfg) port;
          repository-path = cfg.dataDir;
          static-dir = cfg.staticDir;
        } // cfg.extraConfig);
        description =
          "gitit config file. Set this manually to override the one built out of the Nix options.";
      };
      srcRepo = mkOption { default = inputs.gitit-repo.url; };
      staticDir = mkOption {
        type = types.path;
        default = "static";
      };
    };
    config = mkMerge [
      (mkIf cfg.enable {
        users = {
          users.gitit = { isSystemUser = true; };
          groups.gitit = { members = [ "gitit" ]; };
        };
        systemd.services.gitit = {
          name = "gitit";
          wantedBy = "network-online.target";
          path = [ pkgs.git ];
          serviceConfig = {
            ExecStartPre = ''
              if [ ! -d "${cfg.dataDir}"]; then
                 mkdir -p ${cfg.dataDir};
                 git clone ${cfg.srcRepo} ${cfg.dataDir};
                 chown -R ${cfg.users.gitit.name}:${cfg.groups.gitit.name} ${cfg.dataDir}
                 chmod -R 700 ${cfg.dataDir}
              fi
            '';
            ExecStart = "${cfg.package}/bin/gitit -f ${gititConfig}";
            RestartSec = 3;
            Restart = "always";
            RestartSteps = 3;
            User = cfg.user;
          };
        };
      })
      (mkIf cfg.nginx.enable {
        services.nginx =  {
          enable = true;
          virtualHosts."${cfg.nginx.hostName}" = {
            forceSSL = true;
            enableACME = true;
            locations."/".proxyPass = "http://127.0.0.1:${cfg.port}/";
          };
        };
      })
    ];
  };
}
