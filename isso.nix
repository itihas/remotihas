localFlake:

{ lib, config, self, inputs, withSystem, ... }: {
  flake.nixosModules.isso = { config, pkgs, lib, ... }: {
    services.isso = {
      enable = true;
      settings = {
        general = {
          host = "https://itihas.review";
          dbpath = "/var/lib/isso/comments.db";
        };
        server.listen = "http://localhost:1234";
        moderation = {
          enabled = true;
          approve-if-email-previously-approved = true;
        };
      };
    };

    services.nginx.virtualHosts."comments.itihas.review" = {
      forceSSL = true;
      enableACME = true;
      locations."/".proxyPass = config.services.isso.settings.server.listen;
    };
  };
}
