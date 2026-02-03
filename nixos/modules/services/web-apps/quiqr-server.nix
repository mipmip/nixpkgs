{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkDefault
    mkPackageOption
    mkOption
    mkIf
    types
    ;
  cfg = config.services.quiqr-server;
  settingsFormat = pkgs.formats.json { };
  configFile = settingsFormat.generate "quiqr-app-config.json" cfg.settings;

in

{

  meta.maintainers = [ lib.maintainers.mipmip ];

  options = {
    services.quiqr-server = {
      enable = mkEnableOption "quiqr-server";
      #package = mkPackageOption pkgs "quiqr.server" { };

      package = mkPackageOption pkgs [
        "quiqr"
        "server"
      ] { };

      group = mkOption {
        type = types.str;
        default = "quiqr";
        description = ''
          Group under which quiqr-server should run.
        '';
      };

      dataDir = lib.mkOption {
        type = lib.types.path;
        default = "/var/lib/quiqr-server";
        description = ''
          Quiqr-server data directory.
        '';
      };

      user = mkOption {
        type = types.str;
        default = "quiqr";
        description = ''
          User under which quiqr-server should run.
        '';
      };

      environmentFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = ''
          Environment file to load extra environment variables from. E.g. API keys.
        '';
      };

      nginx = {
        enable = mkOption {
          type = types.bool;
          default = true;
          example = false;
          description = ''
            Whether to set up an nginx virtual host.
          '';
        };
        enableSSL = lib.mkOption {
          type = lib.types.bool;
          description = "Enable SSL with Lets Encrypt";
          default = false;
        };
        acme_email = mkOption {
          type = types.str;
          description = ''
            if `enableSSL=true` enter an admin mail address for Lets Encrypt.
          '';
        };

        basicAuthFile = mkOption {
          type = types.nullOr types.path;
          default = null;
          example = "/path/to/htpasswd";
          description = "Path to htpassword file.";
        };

        domain = mkOption {
          type = types.str;
          example = "quiqr.example.com";
          default = "localhost";
          description = ''
            The domain name under which to set up the virtual host.
          '';
        };
      };

    };
  };

  config = mkIf cfg.enable {

    systemd.services.quiqr-server = {
      description = "quiqr-server";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        StateDirectory = "quiqr-server";
        WorkingDirectory = "${cfg.dataDir}";
        User = cfg.user;
        Group = cfg.group;
        ExecStart = "${cfg.package}/bin/quiqr-server";
        path = [
          pkgs.go
          pkgs.hugo
          pkgs.git
        ];

        #ProtectSystem = "full";
        #SystemCallArchitectures = "native";
        #MemoryDenyWriteExecute = true;
        #NoNewPrivileges = true;
        #PrivateTmp = true;
        #PrivateDevices = true;
        #RestrictAddressFamilies = [
        #  "AF_INET"
        #  "AF_INET6"
        #  "AF_UNIX"
        #  "AF_NETLINK"
        #];
        #RestrictNamespaces = true;
        #RestrictRealtime = true;
        #DevicePolicy = "closed";
        #ProtectClock = true;
        #ProtectHostname = true;
        #ProtectProc = "invisible";
        #ProtectControlGroups = true;
        #ProtectKernelModules = true;
        #ProtectKernelTunables = true;
        #LockPersonality = true;
        Restart = "on-failure";
      }
      // lib.optionalAttrs (cfg.environmentFile != null) { EnvironmentFile = cfg.environmentFile; };
    };

    security.acme = lib.attrsets.optionalAttrs cfg.nginx.enableSSL {
      acceptTerms = true;
      defaults.email = cfg.nginx.acme_email;
    };

    services = {
      nginx = mkIf cfg.nginx.enable {
        enable = true;

        recommendedGzipSettings = mkDefault true;
        recommendedOptimisation = mkDefault true;
        recommendedProxySettings = mkDefault true;
        recommendedTlsSettings = mkDefault true;
        virtualHosts.${cfg.nginx.domain} = {

          basicAuthFile = cfg.nginx.basicAuthFile;
          extraConfig = ''
            more_set_headers Referrer-Policy same-origin;
            more_set_headers X-Content-Type-Options nosniff;
          '';
          locations = {
            "/" = {
              alias = "${cfg.package}/opt/quiqr-server/packages/frontend/build/";
              extraConfig = ''
                access_log off;
                more_set_headers Cache-Control "public";
                expires 365d;
              '';
            };
          };
        }
        // lib.attrsets.optionalAttrs cfg.nginx.enableSSL {
          enableACME = true;
          forceSSL = true;
        };
      };
    };

    users = {
      groups.${cfg.group} = { };
      users.${cfg.user} = {
        isSystemUser = true;
        home = "${cfg.dataDir}";
        inherit (cfg) group;
      };
    };

  };
}
