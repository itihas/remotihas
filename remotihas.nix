localFlake:

{
  lib,
  config,
  self,
  inputs,
  withSystem,
  ...
}:
{
  flake.nixosModules.disko =
    { config, pkgs, ... }:
    {
      imports = [ inputs.disko.nixosModules.disko ];
      disko.devices = {
        disk = {
          main = {
            type = "disk";
            device = "/dev/sda";
            content = {
              type = "table";
              format = "msdos";
              partitions = [
                {
                  part-type = "primary";
                  fs-type = "btrfs";
                  name = "root";
                  bootable = true;
                  content = {
                    type = "btrfs";
                    extraArgs = [ "-f" ]; # Override existing partition
                    mountpoint = "/";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                }
              ];
            };
          };

        };
      };
    };

  flake.nixosConfigurations.remotihas = withSystem "x86_64-linux" (
    { config, system, ... }:
    inputs.nixpkgs.lib.nixosSystem {
      modules = with self.nixosModules; [
        (
          { modulesPath, ... }:
          {
            imports = [
              (modulesPath + "/installer/scan/not-detected.nix")
              (modulesPath + "/profiles/qemu-guest.nix")
            ];
          }
        )
        gitit
        zitadel
        myFormats
        itihas
        isso
        ente
        hedgedoc
        outline
        disko
        postfix
        monitoring
        inputs.sops-nix.nixosModules.sops
        inputs.nixos-facter-modules.nixosModules.facter
        (
          {
            config,
            lib,
            pkgs,
            ...
          }:
          {

            networking.useDHCP = lib.mkDefault true;
            nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
            boot.loader.grub.enable = true;
            boot.loader.grub.device = "/dev/sda";
            networking.hostName = "remotihas";
            networking.fqdn = "itihas.xyz";
            networking.useNetworkd = true;
            systemd.network.enable = true;

            sops.defaultSopsFile = ./secrets/remotihas/secrets.yaml;
            sops.age.keyFile = "/var/lib/sops-nix/key.txt";
            # This will generate a new key if the key specified above does not exist
            sops.age.generateKey = true;

            services.gitit = {
              enable = true;
              authenticationMethod = "form";
              nginx = {
                enable = true;
                hostName = "gitit.${config.networking.fqdn}";
              };
            };

            # services.redmine.enable = true;
            # services.nginx.virtualHosts."project.${config.networking.fqdn}" = {
            #   forceSSL = true;
            #   enableACME = true;
            #   locations."/".proxyPass =
            #     "http://localhost:${toString config.services.redmine.port}";
            # };

            # sops.secrets."oauth2-proxy/clientSecret" = { };
            # sops.secrets."oauth2-proxy/cookieSecret" = { };
            # sops.templates."oauth2-proxy-keyfile".content = ''
            #   OAUTH2_PROXY_CLIENT_SECRET=${
            #     config.sops.placeholder."oauth2-proxy/clientSecret"
            #   }
            #   OAUTH2_PROXY_COOKIE_SECRET=${
            #     config.sops.placeholder."oauth2-proxy/cookieSecret"
            #   }
            # '';
            # services.oauth2-proxy = {
            #   enable = true;
            #   provider = "oidc";
            #   passAccessToken = true;
            #   passBasicAuth = true;
            #   email.domains = [ "*" ];
            #   redirectURL =
            #     "http://proxy.${config.networking.fqdn}/oauth2/callback";
            #   oidcIssuerUrl = "https://auth.${config.networking.fqdn}";
            #   cookie = {
            #     secure = true;
            #     domain = config.networking.fqdn;
            #   };
            #   reverseProxy = true;
            #   setXauthrequest = true;
            #   upstream = [ "static://200" ];
            #   nginx = {
            #     domain = "proxy.${config.networking.fqdn}";
            #   };
            #   clientID = "331480552219672577";
            #   keyFile = config.sops.templates."oauth2-proxy-keyfile".path;
            # };

            # services.grocy = {
            #   enable = true;
            #   hostName = "grocy.${config.networking.fqdn}";
            #   nginx.enableSSL = true;
            #   settings = {
            #     currency = "INR";
            #     culture = "en_GB";
            #   };
            # };

            # environment.etc."grocy/config.php".text = ''
            #   Setting('AUTH_CLASS', 'Grocy\Middleware\ReverseProxyAuthMiddleware');
            #   Setting('REVERSE_PROXY_AUTH_USE_ENV','true');
            # '';
            # services.nginx.virtualHosts."grocy.${config.networking.fqdn}".locations."~ \\.php$".extraConfig =
            #   ''
            #     fastcgi_param REMOTE_USER $user;
            #   '';

            sops.secrets."vikunja/oidcClientSecret" = { };
            sops.secrets."vikunja/postgresPassword" = { };
            sops.templates."vikunja-secrets" = {
              content = ''
                VIKUNJA_AUTH_OPENID_PROVIDERS_authihas_CLIENTSECRET=${
                  config.sops.placeholder."vikunja/oidcClientSecret"
                }
                VIKUNJA_DATABASE_PASSWORD=${config.sops.placeholder."vikunja/postgresPassword"}
              '';
            };

            services.postgresql = {
              ensureUsers = [
                {
                  name = "vikunja";
                  ensureDBOwnership = true;
                }
              ];
              ensureDatabases = [ "vikunja" ];
            };
            services.vikunja = {
              enable = true;
              frontendScheme = "http";
              frontendHostname = "vikunja.${config.networking.fqdn}";
              port = 2044;
              database = {
                type = "postgres";
                user = "vikunja";
              };
              environmentFiles = [ config.sops.templates."vikunja-secrets".path ];
              settings = {
                service = {
                  enableregistration = false;
                  enableemailreminders = true;
                  maxavatarsize = 4096;
                  jwtttl = 2592000;
                  jwtttllong = 25920000;
                  maxitemsperpage = 100;
                };
                auth = {
                  local.enabled = false;
                  openid = {
                    enabled = true;
                    providers = {
                      authihas = {
                        name = "authihas";
                        authurl = "https://auth.${config.networking.fqdn}";
                        clientid = "372878888193325701";
                        scope = "openid profile email";
                        forceuserinfo = false;
                      };
                    };
                  };
                };
              };
            };

            services.nginx.virtualHosts."vikunja.${config.networking.fqdn}" = {
              forceSSL = true;
              enableACME = true;
              locations."/" = {
                proxyPass = "http://localhost:${toString config.services.vikunja.port}";
                proxyWebsockets = true;
                extraConfig = ''
                  client_max_body_size 5000M;
                  proxy_read_timeout   600s;
                  proxy_send_timeout   600s;
                  send_timeout         600s;
                '';
              };
            };

            services.privatebin = {
              enable = true;
              enableNginx = true;
              virtualHost = "paste.${config.networking.fqdn}";
              settings = {
                main = {
                  name = "pastihas";
                  discussion = false;
                  defaultformatter = "plalib.types.intext";
                  qrcode = true;
                  template = "bootstrap-dark-page";
                };
                model.class = "Filesystem";
                model_options.dir = "/var/lib/privatebin/data";
              };
            };

            services.headscale = {
              enable = true;
              address = "0.0.0.0";
              port = 8080;
              settings = {
                logtail.enabled = false;
                server_url = "https://headscale.${config.networking.fqdn}";
                metrics_listen_addr = "127.0.0.1:8081";
                dns = {
                  magic_dns = true;
                  nameservers.global = [
                    "9.9.9.9"
                    "1.1.1.1"
                    "8.8.8.8"
                  ];
                  base_domain = "itihas.internal";
                };
              };
            };
            services.prometheus.scrapeConfigs = [
              {
                job_name = "headscale";
                static_configs = [
                  {
                    targets = [ config.services.headscale.settings.metrics_listen_addr ];
                  }
                ];
              }
            ];

            services.nginx.virtualHosts."headscale.${config.networking.fqdn}" = {
              forceSSL = true;
              enableACME = true;
              locations."/" = {
                proxyPass = "http://localhost:${toString config.services.headscale.port}";
                proxyWebsockets = true;
              };
            };

            environment.systemPackages = with pkgs; [
              config.services.headscale.package
              vim
              git
              htop
              wget
            ];

            services.fail2ban.enable = true;

            security.acme = {
              acceptTerms = true;
              defaults.email = "sahiti93@gmail.com";
            };

            services.nginx = {

              # Use recommended settings
              recommendedGzipSettings = true;
              recommendedOptimisation = true;
              recommendedProxySettings = true;
              recommendedTlsSettings = false; # mostly reproduced in commonHttpConfig
              commonHttpConfig =
                let
                  realIpsFromList = lib.strings.concatMapStringsSep "\n" (x: "set_real_ip_from  ${x};");
                  fileToList = x: lib.strings.splitString "\n" (builtins.readFile x);
                  cfipv4 = fileToList (
                    pkgs.fetchurl {
                      url = "https://www.cloudflare.com/ips-v4";
                      sha256 = "0ywy9sg7spafi3gm9q5wb59lbiq0swvf0q3iazl0maq1pj1nsb7h";
                    }
                  );
                  cfipv6 = fileToList (
                    pkgs.fetchurl {
                      url = "https://www.cloudflare.com/ips-v6";
                      sha256 = "1ad09hijignj6zlqvdjxv7rjj8567z357zfavv201b9vx3ikk7cy";
                    }
                  );
                in
                ''
                    ${realIpsFromList cfipv4}
                    ${realIpsFromList cfipv6}
                  real_ip_header CF-Connecting-IP;

                  # reproducing recommendedTlsSettings here with just the ssl_conf_command directive commented out.
                  # ssl_conf_command Groups "X25519MLKEM768:X25519:P-256:P-384";
                  ssl_session_timeout 1d;
                  ssl_session_cache shared:SSL:10m;
                  # Breaks forward secrecy: https://github.com/mozilla/server-side-tls/issues/135
                  ssl_session_tickets off;
                  # We don't enable insecure ciphers by default, so this allows
                  # clients to pick the most performant, per https://github.com/mozilla/server-side-tls/issues/260
                  ssl_prefer_server_ciphers off;
                '';

              virtualHosts.${config.services.privatebin.virtualHost} = {
                forceSSL = true;
                enableACME = true;
              };

            };

            services.openssh.enable = true;
            networking.firewall.allowedTCPPorts = [
              22
              80
              443
            ];
          }
        )
      ];
    }
  );

}
