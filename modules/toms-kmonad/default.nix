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

            ;; Define aliases
            (defalias
              ;; Left-hand home row mods
              a-sft (tap-hold-next-release 200 a lsft)
              s-ctl (tap-hold-next-release 200 s lctl)
              d-alt (tap-hold-next-release 200 d lalt)
              f-met (tap-hold-next-release 200 f lmet)

              ;; Right-hand home row mods
              j-met (tap-hold-next-release 200 j rmet)
              k-alt (tap-hold-next-release 200 k ralt)
              l-ctl (tap-hold-next-release 200 l rctl)
              sem-sft (tap-hold-next-release 200 ; rsft)

              ;; Layer toggle for caps lock
              ;; Tap for escape, hold for nav layer
              nav (tap-hold 200 esc (layer-toggle nav))

              ;; Navigation and editing aliases
              prev C-left     ;; Previous word
              next C-right    ;; Next word
              beg home        ;; Beginning of line
              end end         ;; End of line
              del del         ;; Delete forward
              bsp bspc        ;; Backspace
              sel S-          ;; Shift modifier for selection
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

            ;; Base layer
            (deflayer default
              esc  f1   f2   f3   f4   f5   f6   f7   f8   f9   f10  f11  f12
              grv  1    2    3    4    5    6    7    8    9    0    -    =    bspc
              tab  q    w    e    r    t    y    u    i    o    p    [    ]    \
              @nav @a-sft @s-ctl @d-alt @f-met g h @j-met @k-alt @l-ctl @sem-sft ' ret
              lsft z    x    c    v    b    n    m    ,    .    /    rsft
              lctl lmet lalt           spc            ralt rmet rctl
            )

            ;; Navigation and editing layer (activated by holding caps lock)
            (deflayer nav
              _    _    _    _    _    _    _    _    _    _    _    _    _
              _    _    _    _    _    _    _    _    _    _    _    _    _    _
              _    _    _    end  _    _    _    home pgdn pgup end  _    _    _
              _    @sel @bsp @del _    _    left down up   rght _    _    _
              _    _    _    _    _    _    _    _    _    _    _    _
              _    _    _              _              _    _    _

              ;; Quick reference for nav layer:
              ;; - hjkl: Vim-style arrow keys
              ;; - u/i: Page up/down
              ;; - y/o: Home/End
              ;; - s: Add selection (shift)
              ;; - d: Backspace
              ;; - f: Delete
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