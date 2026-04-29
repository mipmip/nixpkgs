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
    mkMerge
    types
    ;
  cfg = config.services.quiqr-server;
  settingsFormat = pkgs.formats.json { };
  configFile = settingsFormat.generate "instance_settings.json" cfg.settings;

in

{

  meta.maintainers = [ lib.maintainers.mipmip ];

  options = {
    services.quiqr-server = {
      enable = mkEnableOption "quiqr-server";

      package = mkPackageOption pkgs [
        "quiqr"
        "server"
      ] { };

      port = mkOption {
        type = types.port;
        default = 5150;
        description = ''
          Port on which the quiqr-server listens.
        '';
      };

      host = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = ''
          Address on which the quiqr-server listens.
          Set to `"0.0.0.0"` to listen on all interfaces.
        '';
      };

      group = mkOption {
        type = types.str;
        default = "quiqr";
        description = ''
          Group under which quiqr-server should run.
        '';
      };

      configDir = mkOption {
        type = types.path;
        default = "/var/lib/quiqr-server";
        description = ''
          Quiqr-server configuration directory.
        '';
      };

      user = mkOption {
        type = types.str;
        default = "quiqr";
        description = ''
          User under which quiqr-server should run.
        '';
      };

      environmentFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = ''
          Environment file to load extra environment variables from. E.g. API keys.
        '';
      };

      settings = mkOption {
        type = types.submodule {
          freeformType = settingsFormat.type;

          options = {
            storage = {
              type = mkOption {
                type = types.enum [
                  "fs"
                  #"s3"
                ];
                default = "fs";
                description = "Storage backend type.";
              };
              dataFolder = mkOption {
                type = types.str;
                default = "~/Quiqr";
                description = "Path where site content data is stored.";
              };
            };

            git = {
              binaryPath = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Path to the git binary. Uses system git if null.";
              };
            };

            logging = {
              retention = mkOption {
                type = types.ints.between 0 365;
                default = 30;
                description = "Log retention in days. 0-365";
              };
              logLevel = mkOption {
                type = types.enum [
                  "debug"
                  "info"
                  "warn"
                  "error"
                ];
                default = "info";
                description = "Logging verbosity level.";
              };
            };

            experimentalFeatures = mkOption {
              type = types.bool;
              default = false;
              description = "Enable experimental features.";
            };

            hugo = {
              serveDraftMode = mkOption {
                type = types.bool;
                default = false;
                description = "Serve Hugo drafts.";
              };
              disableAutoHugoServe = mkOption {
                type = types.bool;
                default = false;
                description = "Disable automatic Hugo serve on workspace open.";
              };
            };

            variables = mkOption {
              type = types.attrsOf types.str;
              default = { };
              description = ''
                Global build action variables. Machine-specific overrides for `%VAR%` substitution in build actions.
              '';
            };

            auth = {
              enabled = mkOption {
                type = types.bool;
                default = false;
                description = ''
                  Enable built-in authentication (LocalFileAuthProvider).
                  On first run, a default admin user (admin@localhost / admin) is created.
                '';
              };
              provider = mkOption {
                type = types.str;
                default = "local";
                description = "Authentication provider.";
              };
              local = {
                usersFile = mkOption {
                  type = types.str;
                  default = "users.json";
                  description = "Filename for the local users database.";
                };
              };
              session = {
                secret = mkOption {
                  type = types.nullOr types.str;
                  default = null;
                  description = ''
                    Session secret for signing tokens. If null, a random secret is generated.
                    Consider using `environmentFile` to pass this as `QUIQR_AUTH_SESSION_SECRET` instead.
                  '';
                };
                accessTokenExpiry = mkOption {
                  type = types.str;
                  default = "15m";
                  description = "Access token expiry duration.";
                };
                refreshTokenExpiry = mkOption {
                  type = types.str;
                  default = "7d";
                  description = "Refresh token expiry duration.";
                };
              };
            };
          };
        };
        default = { };
        description = ''
          Configuration for quiqr-server, written to `instance_settings.json`.
          See the `instanceSettingsSchema` in the quiqr-desktop source for all available settings.
        '';
      };

      nginx = {
        enable = mkOption {
          type = types.bool;
          default = false;
          example = true;
          description = ''
            Whether to set up an nginx reverse proxy virtual host.
          '';
        };
        enableSSL = mkOption {
          type = types.bool;
          description = "Enable SSL with Lets Encrypt.";
          default = false;
        };
        acme_email = mkOption {
          type = types.str;
          default = "";
          description = ''
            If `enableSSL=true` enter an admin mail address for Lets Encrypt.
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
      environment = {
        PORT = toString cfg.port;
        HOST = cfg.host;
        QUIQR_CONF_DIR = cfg.configDir;
        QUIQR_CONFIG_FILE = "${cfg.configDir}/instance_settings.json";
        NODE_ENV = "production";
      };
      preStart = ''
        mkdir -p ${cfg.configDir}
        install -m 0644 ${configFile} ${cfg.configDir}/instance_settings.json
      '';
      serviceConfig = mkMerge [
        {
          Type = "simple";
          StateDirectory = "quiqr-server";
          WorkingDirectory = cfg.configDir;
          User = cfg.user;
          Group = cfg.group;
          ExecStart = "${cfg.package}/bin/quiqr-server";
          Restart = "on-failure";
        }
        (mkIf (cfg.environmentFile != null) {
          EnvironmentFile = cfg.environmentFile;
        })
      ];
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
              proxyPass = "http://${cfg.host}:${toString cfg.port}";
              proxyWebsockets = true;
            };
          };
        }
        // lib.attrsets.optionalAttrs cfg.nginx.enableSSL {
          enableACME = true;
          forceSSL = true;
        };
      };
    };

    environment.systemPackages = [
      (pkgs.runCommand "quiqr-admin" { nativeBuildInputs = [ pkgs.makeWrapper ]; } ''
        mkdir -p $out/bin
        makeWrapper ${cfg.package}/bin/quiqr-admin $out/bin/quiqr-admin \
          --set QUIQR_CONF_DIR ${cfg.configDir}
      '')
    ];

    users = {
      groups.${cfg.group} = { };
      users.${cfg.user} = {
        isSystemUser = true;
        home = cfg.configDir;
        inherit (cfg) group;
      };
    };

  };
}
