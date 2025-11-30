localFlake:

{ config, pkgs, lib, ... }: {
  flake.nixosModules.postfix = { config, lib, pkgs, ... }: {

    sops.secrets."postfix/smtpPassword" = {
      owner = "dovecot2";
      group = "dovecot2";
    };

    sops.templates."dovecot-users" = {
      owner = "dovecot2";
      group = "dovecot2";
      content = ''
        zitadel:{PLAIN}${config.sops.placeholder."postfix/smtpPassword"}:::::
      '';
    };
    services.postfix = {
      enable = true;
      hostname = config.networking.fqdn;
      destination = [ config.networking.fqdn ];
      config = {
        smtp_tls_security_level = "may";
        smtp_tls_note_starttls_offer = "yes";
        smtpd_tls_cert_file =
          "/var/lib/acme/${config.networking.fqdn}/cert.pem";
        smtpd_tls_key_file = "/var/lib/acme/${config.networking.fqdn}/key.pem";
        # SASL auth setup
        smtpd_sasl_auth_enable = "yes";
        smtpd_sasl_type = "dovecot";
        smtpd_sasl_path = "private/auth";
        smtpd_recipient_restrictions =
          [ "permit_sasl_authenticated" "reject_unauth_destination" ];
      };
    };

    services.dovecot2 = {
      enable = true;
      enablePAM = false;
      extraConfig = ''
        # Just for SASL auth, not full mail storage
        service auth {
          unix_listener /var/lib/postfix/queue/private/auth {
            mode = 0660
            user = postfix
            group = postfix
          }
        }

        passdb {
          driver = passwd-file
          args = ${config.sops.templates."dovecot-users".path}
        }
      '';
    };
  };
}
