{ config,
  lib,
  pkgs,
  ... }:

with lib;

let
  cfg = config.services.clubcotton.toms-kmonad;
in
{
  options.services.clubcotton.toms-kmonad = {
    enable = mkEnableOption "kmonad";

    platform = mkOption {
      type = types.enum [ "linux" "darwin" ];
      default = if pkgs.stdenv.isDarwin then "darwin" else "linux";
      description = "Platform to configure kMonad for (linux or darwin)";
    };

    linuxKeyboardPath = mkOption {
      type = types.str;
      description = "Path to keyboard device on Linux. ex: /dev/input/by-id/your-keyboard-device";
    };

    macKeyboardName = mkOption {
      type = types.str;
      default = "Apple Internal Keyboard";
      description = "Name of keyboard device on MacOS";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      # Required packages
      environment.systemPackages = [ pkgs.kmonad ];

      services.kmonad = {
        enable = true;
        keyboards = {
          main = {
            device = if cfg.platform == "darwin"
              then ''-device "${cfg.macKeyboardName}"''
              else cfg.linuxKeyboardPath;

            config = ''
              (defcfg
              ${if cfg.platform == "darwin" then ''
                input  (iokit-name "${cfg.macKeyboardName}")
                output (kext)
              '' else ''
                input  (device-file "${cfg.linuxKeyboardPath}")
                output (uinput-sink "KMonad output")
              ''}
                cmp-seq-delay 5
                cmp-seq-timeout 10
                fallthrough true
                allow-cmd false
              )

              ;; Define aliases
              (defalias
                ;; Home row mods
                a-sft (tap-hold-next-release 200 a lsft)
                s-ctl (tap-hold-next-release 200 s lctl)
                d-alt (tap-hold-next-release 200 d lalt)
                f-met (tap-hold-next-release 200 f lmet)
                j-met (tap-hold-next-release 200 j rmet)
                k-alt (tap-hold-next-release 200 k ralt)
                l-ctl (tap-hold-next-release 200 l rctl)
                sem-sft (tap-hold-next-release 200 ; rsft)

                ;; Layer toggle for caps lock
                nav (tap-hold 0 esc (layer-toggle nav))

                ;; Navigation and editing aliases
                del del
                bsp bspc
                beg home
                end end
                nwd C-right
                pwd C-left
                excl !
                at @
                hash #
                doll $
                perc %
                caret ^
                amp &
                star *
                lprn (
                rprn )
                min -
                plus +
                eq =
                uns _
              )

              ;; Base layer
              (deflayer default
                esc   f1   f2   f3   f4   f5   f6   f7   f8   f9   f10  f11  f12
                grv   1    2    3    4    5    6    7    8    9    0    -    =    bspc
                tab   q    w    e    r    t    y    u    i    o    p    [    ]    \
                @nav  @a-sft @s-ctl @d-alt @f-met g h @j-met @k-alt @l-ctl @sem-sft ' ret
                lsft  z    x    c    v    b    n    m    ,    .    /    rsft
                lctl  lalt lmet spc  rmet _    rctl
              )

              ;; Navigation layer
              (deflayer nav
                esc   f1   f2   f3   f4   f5   f6   f7   f8   f9   f10  f11  f12
                grv   1    2    3    4    5    6    7    8    9    0    -    =    bspc
                tab   q    kp7  kp8  kp9  t    \(   \)   up   {    }    [    ]    \
                _     a    kp4  kp5  kp6  g    bspc left down rght ;    '    ret
                lsft  kp1  kp2  kp3  v    b    @uns -    ,    .    /    rsft
                lctl  lalt lmet spc  ralt _    rctl
              )
            '';
          };
        };
      };
    }

    (mkIf (cfg.platform == "linux") {
      # User permissions
      users.groups.uinput = {};
      users.groups.input = {};
      users.users.${config.user.name}.extraGroups = [ "input" "uinput" ];

      # Kernel modules
      boot.kernelModules = [ "uinput" ];

      # UDev rules
      services.udev.extraRules = ''
        # KMonad user access to /dev/uinput
        KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
        # KMonad user access to input devices
        KERNEL=="event*", NAME="input/%k", MODE="0640", GROUP="input"
      '';
    })

    (mkIf (cfg.platform == "darwin") {
      # LaunchDaemons for kmonad
      launchd.daemons.kmonad = {
        serviceConfig = {
          Label = "com.kmonad.service";
          ProgramArguments = [
            "${pkgs.kmonad}/bin/kmonad"
            "-device"
            cfg.macKeyboardName
          ];
          RunAtLoad = true;
          KeepAlive = true;
          StandardOutPath = "/var/log/kmonad.log";
          StandardErrorPath = "/var/log/kmonad.error.log";
        };
      };

      # System extensions and permissions
      system.defaults.security = {
        # Enable system extensions from identified developers
        allowNonAdministratorsToLoadExtensions = true;
        enableAssessment = true;
      };

      # Required system settings for input monitoring
      system.defaults.NSGlobalDomain = {
        # Enable accessibility features
        "com.apple.security.temporary-exception.apple-events" = "*";
        "com.apple.security.temporary-exception.mach-lookup.global-name" = [
          "com.apple.coreservices.launchservicesd"
          "com.apple.systemuiserver"
        ];
      };

      # TCC (Transparency, Consent, and Control) Database entries
      system.activationScripts.postActivation.text = ''
        # Add KMonad to Input Monitoring
        /usr/bin/sqlite3 "$HOME/Library/Application Support/com.apple.TCC/TCC.db" '
          INSERT OR REPLACE INTO access
          (service, client, client_type, auth_value, auth_reason, auth_version)
          VALUES
          ("kTCCServiceListenEvent",
           "${pkgs.kmonad}/bin/kmonad",
           1,
           2,
           4,
           1)
        '
      '';
    })
  ]);
}