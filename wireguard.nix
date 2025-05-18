localFlake:

{ lib, config, self, inputs, ... }: {
  flake.nixosModules.wireguard = { config, lib, pkgs, ... }: {
    networking.firewall.allowedUDPPorts = [ 51820 ];
    networking.useNetworkd = true;
    systemd.network = {
      enable = true;
      netdevs = {
        "50-wg0" = {
          netdevConfig = {
            Kind = "wireguard";
            Name = "wg0";
            MTUBytes = "1300";
          };
          wireguardConfig = {
            PrivateKeyFile = "/private/wireguard_key";
            ListenPort = 51820;
          };
          wireguardPeers = [
            {
              PublicKey = "pYkL/P1D8lwAAxlz7G7kDg2ktjNv+EiRTgsqTqAebh0=";
              PersistentKeepalive = 15;
              AllowedIPs = [ "10.100.0.2/32" ];
            }
            {
              PublicKey = "s+Ij2Z9NgxhostXt0eSNTHEEXLLDaee1yPAGjo3PWw8=";
              PersistentKeepalive = 15;
              AllowedIPs = [ "10.100.0.3/32" ];

            }
          ];
        };
      };
      networks.wg0 = {
        matchConfig.Name = "wg0";
        address = [ "10.100.0.1/24" ];
        networkConfig = {
          IPMasquerade = "both";
          IPv4Forwarding = true;
          IPv6Forwarding = true;
        };
      };
    };
    environment.systemPackages = [ pkgs.wireguard-tools ];
  };
}
