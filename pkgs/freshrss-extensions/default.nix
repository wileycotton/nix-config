{
  config,
  lib,
  fetchFromGitHub,
  callPackage,
}:

let
  buildFreshRssExtension = (callPackage ../../../nixpkgs/pkgs/servers/web-apps/freshrss/extensions/freshrss-utils.nix { }).buildFreshRssExtension;

  baseExtensions =
    _self:
    lib.mapAttrs (_n: lib.recurseIntoAttrs) {
      readable = buildFreshRssExtension {
        FreshRssExtUniqueId = "Readable";
        pname = "readable";
        version = "unstable-2024-02-06";
        src = fetchFromGitHub {
          owner = "printfuck";
          repo = "xExtension-Readable";
          rev = "master";
          hash = "sha256-0gyqb5bj17ywv75wsizyivd12jm87bxar9bkki49qa0bibjcad3w=";
        };
        meta = with lib; {
          description = "A FreshRSS extension that makes articles more readable";
          homepage = "https://github.com/printfuck/xExtension-Readable";
          license = licenses.mit;
          maintainers = [ ];
        };
      };
    };

  overlays = lib.optionals config.allowAliases [
    (_self: super: lib.recursiveUpdate super { })
  ];

  toFix = lib.foldl' (lib.flip lib.extends) baseExtensions overlays;
in
(lib.fix toFix)
// {
  inherit buildFreshRssExtension;
}
