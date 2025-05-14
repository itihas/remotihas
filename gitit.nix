localFlake:

{ lib, config, self, inputs, ... }:
with lib;

{
  flake.nixosModules.gitit = { config, lib, pkgs, ... }:
    let
      cfg = config.services.gitit;
    in {
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
                  The hostname used to setup the virtualhost configuration
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
          default = "/data/gitit";
          description = ''
            Location where Gitit stores its data. This will be version-controlled.
            If the location doesn't exist or is empty, the service pre-start will create this location and try to git clone `services.gitit.srcRepo` to `{dataDir}/wikidata`.
          '';
        };
        extraConfig = mkOption {
          type = types.attrs;
          default = { };
          description = "attributes to append to the gitit config.";
        };
        config = mkOption {
          default = null;
          type = with types; nullOr str;
          description =
            "gitit config file. Set this manually to override the one built out of the Nix options.";
        };
        srcRepo = mkOption { default = ""; };
      };
      config = let
        mkGititConfig = with pkgs.lib.generators;
          s:
          (toINIWithGlobalSection { mkKeyValue = mkKeyValueDefault { } ":"; }) {
                                      globalSection = s;
                                    };
        gititConf = pkgs.writeTextFile {
          name = "gitit.conf";
          text = if !(builtins.isNull cfg.config) then cfg.config else mkGititConfig ({
            inherit (cfg) port; # should replace this whole thing with a patch script on the default config
            repository-path = "${cfg.dataDir}/wikidata";
            static-dir = "${cfg.dataDir}/static";
            templates-dir = "${cfg.dataDir}/templates";
            cache-dir = "${cfg.dataDir}/cache";
            pandoc-user-data = "${cfg.dataDir}/pandoc-user-data";
            user-file = "${cfg.dataDir}/gitit-users";
            log-file = "${cfg.dataDir}/gitit.log";
          } // cfg.extraConfig);
        };
        preStartScript = pkgs.writeShellScript "gitit-pre-start.sh" ''
                if [ ! -d "${cfg.dataDir}" ]; then
                   mkdir -p ${cfg.dataDir} ;
                   git clone ${cfg.srcRepo} ${cfg.dataDir}/wikidata || true ; # this will fail if srcRepo is unset,
                   # in which case we let gitit handle the repo creation.
                   chown -R ${config.users.users.gitit.name}:${config.users.groups.gitit.name} ${cfg.dataDir} ;
                   chmod -R 700 ${cfg.dataDir} ;
                fi
              '';
      in mkMerge [
        (mkIf cfg.enable {
          users = {
            users.gitit = {
              isSystemUser = true;
              group = "gitit";
            };
            groups.gitit = { };
          };
          systemd.services.gitit = {
            wantedBy = [ "network.target" ];
            path = [ pkgs.git ];
            serviceConfig = {
              ExecStartPre = "+${pkgs.bash}/bin/bash -c ${preStartScript}";
              ExecStart = "${cfg.package}/bin/gitit -f ${gititConf}";
              RestartSec = 3;
              Restart = "always";
              RestartSteps = 3;
              User = config.users.users.gitit.name;
            };
          };
        })
        (mkIf cfg.nginx.enable {
          services.nginx = {
            enable = true;
            virtualHosts."${cfg.nginx.hostName}" = {
              # forceSSL = true;
              # enableACME = true;
              locations."/".proxyPass =
                "http://127.0.0.1:${builtins.toString cfg.port}/";
            };
          };
        })
      ];
    };
}
