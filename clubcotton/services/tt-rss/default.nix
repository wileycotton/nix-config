{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.clubcotton.tt-rss;
  clubcotton = config.clubcotton; # this fails in tests with the following error aka fuckery
in {
  options.services.clubcotton.tt-rss = {
    enable = mkEnableOption "Simple webhosted RSS reader with good plugin support.";

    port = mkOption {
      type = types.port;
      default = 8280;
      description = "Port for tt-rss to listen on.";
    };
    root = mkOption {
      type = types.path;
      default = "/var/lib/tt-rss";
      description = ''
        Root of the application.
      '';
    };

    user = mkOption {
      type = types.str;
      default = "tt_rss";
      description = ''
        User account under which both the update daemon and the web-application run.
      '';
    };

    database = {
      type = mkOption {
        type = types.enum ["pgsql" "mysql"];
        default = "pgsql";
        description = ''
          Database to store feeds. Supported are pgsql and mysql.
        '';
      };

      host = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Host of the database. Leave null to use Unix domain socket.
        '';
      };

      name = mkOption {
        type = types.str;
        default = "tt_rss";
        description = ''
          Name of the existing database.
        '';
      };

      user = mkOption {
        type = types.str;
        default = "tt_rss";
        description = ''
          The database user. The user must exist and has access to
          the specified database.
        '';
      };

      password = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          The database user's password.
        '';
      };

      passwordFile = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          The database user's password.
        '';
      };

      port = mkOption {
        type = types.nullOr types.port;
        default = null;
        description = ''
          The database's port. If not set, the default ports will be provided (5432
          and 3306 for pgsql and mysql respectively).
        '';
      };

      createLocally = mkOption {
        type = types.bool;
        default = true;
        description = "Create the database and database user locally.";
      };
    };

    auth = {
      autoCreate = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Allow authentication modules to auto-create users in tt-rss internal
          database when authenticated successfully.
        '';
      };

      autoLogin = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Automatically login user on remote or other kind of externally supplied
          authentication, otherwise redirect to login form as normal.
          If set to true, users won't be able to set application language
          and settings profile.
        '';
      };
    };

    sphinx = {
      server = mkOption {
        type = types.str;
        default = "localhost:9312";
        description = ''
          Hostname:port combination for the Sphinx server.
        '';
      };

      index = mkOption {
        type = types.listOf types.str;
        default = ["ttrss" "delta"];
        description = ''
          Index names in Sphinx configuration. Example configuration
          files are available on tt-rss wiki.
        '';
      };
    };

    email = {
      server = mkOption {
        type = types.str;
        default = "";
        example = "localhost:25";
        description = ''
          Hostname:port combination to send outgoing mail. Blank - use system
          MTA.
        '';
      };

      login = mkOption {
        type = types.str;
        default = "";
        description = ''
          SMTP authentication login used when sending outgoing mail.
        '';
      };

      password = mkOption {
        type = types.str;
        default = "";
        description = ''
          SMTP authentication password used when sending outgoing mail.
        '';
      };

      security = mkOption {
        type = types.enum ["" "ssl" "tls"];
        default = "";
        description = ''
          Used to select a secure SMTP connection. Allowed values: ssl, tls,
          or empty.
        '';
      };

      fromName = mkOption {
        type = types.str;
        default = "Tiny Tiny RSS";
        description = ''
          Name for sending outgoing mail. This applies to password reset
          notifications, digest emails and any other mail.
        '';
      };

      fromAddress = mkOption {
        type = types.str;
        default = "";
        description = ''
          Address for sending outgoing mail. This applies to password reset
          notifications, digest emails and any other mail.
        '';
      };
    };

    selfUrlPath = mkOption {
      type = types.str;
      description = ''
        Full URL of your tt-rss installation. This should be set to the
        location of tt-rss directory, e.g. http://example.org/tt-rss/
        You need to set this option correctly otherwise several features
        including PUSH, bookmarklets and browser integration will not work properly.
      '';
      example = "http://localhost";
    };

    feedCryptKey = mkOption {
      type = types.str;
      default = "";
      description = ''
        Key used for encryption of passwords for password-protected feeds
        in the database. A string of 24 random characters. If left blank, encryption
        is not used. Requires mcrypt functions.
        Warning: changing this key will make your stored feed passwords impossible
        to decrypt.
      '';
    };

    forceArticlePurge = mkOption {
      type = types.int;
      default = 0;
      description = ''
        When this option is not 0, users ability to control feed purging
        intervals is disabled and all articles (which are not starred)
        older than this amount of days are purged.
      '';
    };

    enableGZipOutput = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Selectively gzip output to improve wire performance. This requires
        PHP Zlib extension on the server.
        Enabling this can break tt-rss in several httpd/php configurations,
        if you experience weird errors and tt-rss failing to start, blank pages
        after login, or content encoding errors, disable it.
      '';
    };

    plugins = mkOption {
      type = types.listOf types.str;
      default = ["auth_internal" "note"];
      description = ''
        List of plugins to load automatically for all users.
        System plugins have to be specified here. Please enable at least one
        authentication plugin here (auth_*).
        Users may enable other user plugins from Preferences/Plugins but may not
        disable plugins specified in this list.
        Disabling auth_internal in this list would automatically disable
        reset password link on the login form.
      '';
    };

    pluginPackages = mkOption {
      type = types.listOf types.package;
      default = [];
      description = ''
        List of plugins to install. The list elements are expected to
        be derivations. All elements in this derivation are automatically
        copied to the `plugins.local` directory.
      '';
    };

    themePackages = mkOption {
      type = types.listOf types.package;
      default = [];
      description = ''
        List of themes to install. The list elements are expected to
        be derivations. All elements in this derivation are automatically
        copied to the `themes.local` directory.
      '';
    };

    updateDaemon = {
      commandFlags = mkOption {
        type = types.str;
        default = "--quiet";
        description = ''
          Command-line flags passed to the update daemon.
          The default --quiet flag mutes all logging, including errors.
        '';
      };
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Additional lines to append to `config.php`.
      '';
    };

    tailnetHostname = mkOption {
      type = types.str;
      default = "";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.database.password != null -> cfg.database.passwordFile == null;
        message = "Cannot set both password and passwordFile";
      }
      {
        assertion = cfg.database.createLocally -> cfg.database.name == cfg.user && cfg.database.user == cfg.user;
        message = ''
          When creating a database via NixOS, the db user and db name must be equal!
          If you already have an existing DB+user and this assertion is new, you can safely set
          `services.tt-rss.database.createLocally` to `false`.
        '';
      }
    ];

    services.tt-rss = {
      enable = true;
      root = cfg.root;
      user = cfg.user;
      database = {
        type = cfg.database.type;
        host = cfg.database.host;
        name = cfg.database.name;
        user = cfg.database.user;
        password = cfg.database.password;
        passwordFile = cfg.database.passwordFile;
        port = cfg.database.port;
        createLocally = cfg.database.createLocally;
      };
      auth = {
        autoCreate = cfg.auth.autoCreate;
        autoLogin = cfg.auth.autoLogin;
      };
      sphinx = {
        server = cfg.sphinx.server;
        index = cfg.sphinx.index;
      };
      email = {
        server = cfg.email.server;
        login = cfg.email.login;
        password = cfg.email.password;
        security = cfg.email.security;
        fromName = cfg.email.fromName;
        fromAddress = cfg.email.fromAddress;
      };
      selfUrlPath = cfg.selfUrlPath;
      feedCryptKey = cfg.feedCryptKey;
      forceArticlePurge = cfg.forceArticlePurge;
      enableGZipOutput = cfg.enableGZipOutput;
      plugins = cfg.plugins;
      pluginPackages = cfg.pluginPackages;
      themePackages = cfg.themePackages;
      updateDaemon.commandFlags = cfg.updateDaemon.commandFlags;
      extraConfig = cfg.extraConfig;
    };

    services.tsnsrv = {
      enable = true;
      defaults.authKeyPath = clubcotton.tailscaleAuthKeyPath;

      services."${cfg.tailnetHostname}" = mkIf (cfg.tailnetHostname != "") {
        ephemeral = true;
        toURL = "http://127.0.0.1:${toString cfg.port}/";
      };
    };
  };
}
