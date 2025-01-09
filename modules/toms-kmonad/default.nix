{ config, 
lib, 
pkgs, 
... }:

with lib;

let
  cfg = config.services.clubcotton.kmonad;
in
{
  options.services.clubcotton.kmonad = {
    enable = mkEnableOption "kmonad";

    platform = mkOption {
      type = types.enum [ "linux" "darwin" ];
      default = if pkgs.stdenv.isDarwin then "darwin" else "linux";
      description = "Platform to configure kMonad for (linux or darwin)";
    };

    linuxKeyboardPath = mkOption {
      type = types.str;
      default = "/dev/input/by-id/your-keyboard-device";
      description = "Path to keyboard device on Linux";
    };

    macKeyboardName = mkOption {
      type = types.str;
      default = "Apple Internal Keyboard";
      description = "Name of keyboard device on MacOS";
    };
  };

  config = mkIf cfg.enable {
    services.kmonad = {
      enable = true;
      keyboards = {
        main = {
          device = if cfg.platform == "darwin"
            then ''-device "${cfg.macKeyboardName}"''
            else cfg.linuxKeyboardPath;

          config = ''
            (defcfg
              ;; Input configuration based on platform
              ${if cfg.platform == "darwin" then ''
                input  (iokit-name "${cfg.macKeyboardName}")
                output (kext)
              '' else ''
                input  (device-file "${cfg.linuxKeyboardPath}")
                output (uinput-sink "KMonad output")
              ''}
              
              ;; Common configuration options
              cmp-seq-delay 5
              cmp-seq-timeout 10
              fallthrough true
              allow-cmd false
            )

            ;; Define aliases for home row mods
            (defalias
              ;; Left-hand home row mods
              a-sft (tap-hold-next-release 200 a lsft)  ;; Shift when held, 'a' when tapped
              s-ctl (tap-hold-next-release 200 s lctl)  ;; Control when held, 's' when tapped
              d-alt (tap-hold-next-release 200 d lalt)  ;; Alt when held, 'd' when tapped
              f-met (tap-hold-next-release 200 f lmet)  ;; Meta/Super when held, 'f' when tapped

              ;; Right-hand home row mods
              j-met (tap-hold-next-release 200 j rmet)  ;; Meta/Super when held, 'j' when tapped
              k-alt (tap-hold-next-release 200 k ralt)  ;; Alt when held, 'k' when tapped
              l-ctl (tap-hold-next-release 200 l rctl)  ;; Control when held, 'l' when tapped
              sem-sft (tap-hold-next-release 200 ; rsft) ;; Shift when held, ';' when tapped

              ;; Additional useful aliases
              cap (tap-hold-next-release 200 esc lctl)  ;; Escape when tapped, Control when held
            )

            ;; Define keyboard source
            (defsrc
              esc  f1   f2   f3   f4   f5   f6   f7   f8   f9   f10  f11  f12
              grv  1    2    3    4    5    6    7    8    9    0    -    =    bspc
              tab  q    w    e    r    t    y    u    i    o    p    [    ]    \
              caps a    s    d    f    g    h    j    k    l    ;    '    ret
              lsft z    x    c    v    b    n    m    ,    .    /    rsft
              lctl lmet lalt           spc            ralt rmet rctl
            )

            ;; Define keyboard mapping with home row mods
            (deflayer default
              esc  f1   f2   f3   f4   f5   f6   f7   f8   f9   f10  f11  f12
              grv  1    2    3    4    5    6    7    8    9    0    -    =    bspc
              tab  q    w    e    r    t    y    u    i    o    p    [    ]    \
              @cap @a-sft @s-ctl @d-alt @f-met g h @j-met @k-alt @l-ctl @sem-sft ' ret
              lsft z    x    c    v    b    n    m    ,    .    /    rsft
              lctl lmet lalt           spc            ralt rmet rctl
            )
          '';
        };
      };
    };

    # Platform-specific configurations
    ${if cfg.platform == "linux" then ''
      environment.systemPackages = with pkgs; [ kmonad ];
      users.users.${config.user.name}.extraGroups = [ "input" "uinput" ];
      boot.kernelModules = [ "uinput" ];
      services.udev.extraRules = ''
        # KMonad user access to /dev/uinput
        KERNEL=="uinput", MODE="0660", GROUP="input", OPTIONS+="static_node=uinput"
      '';
    '' else ""}
  };
}