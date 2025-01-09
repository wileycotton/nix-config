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
      description = "Path to keyboard device on Linux. ex: /dev/input/by-id/your-keyboard-device";
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
              ;; Home row mods (same as before)
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
              del del         ;; Delete forward
              bsp bspc        ;; Backspace
              
              ;; Quick text navigation
              beg home        ;; Beginning of line
              end end         ;; End of line
              nwd C-right     ;; Next word
              pwd C-left      ;; Previous word
              
              ;; Common symbols for nav layer
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

            ;; Base layer (same as before)
            (deflayer default
              esc  f1   f2   f3   f4   f5   f6   f7   f8   f9   f10  f11  f12
              grv  1    2    3    4    5    6    7    8    9    0    -    =    bspc
              tab  q    w    e    r    t    y    u    i    o    p    [    ]    \
              @nav @a-sft @s-ctl @d-alt @f-met g h @j-met @k-alt @l-ctl @sem-sft ' ret
              lsft z    x    c    v    b    n    m    ,    .    /    rsft
              lctl lalt lmet           spc            rmet _    rctl
            )

            ;; Navigation layer - exactly like default keyboard except IJKL
            (deflayer nav
              esc  f1   f2   f3   f4   f5   f6   f7   f8   f9   f10  f11  f12
              grv  1    2    3    4    5    6    7    8    9    0    -    =    bspc
              tab  q    kp7  kp8  kp9  t    \(   \)   up   {    }    [    ]    \
              _    a    kp4  kp5  kp6  g    bspc left down rght ;    '    ret
              lsft kp1  kp2  kp3  v    b    @uns -    ,    .    /    rsft
              lctl lalt lmet           spc            ralt _    rctl

              ;; Quick reference for nav layer:
              ;; - IJKL: Arrow keys
              ;; - U: Home
              ;; - O: End
              ;; - H: Backspace
              ;; - G: Delete
              ;; - Top row: Common symbols (!@#$%^&*()_+)
              ;; - Other useful navigation remains accessible
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