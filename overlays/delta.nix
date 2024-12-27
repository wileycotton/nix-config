{
  config,
  pkgs,
  lib,
  unstablePkgs,
  ...
}: self: super: {
  delta = super.delta.overrideAttrs (previousAttrs: {
    postInstall =
      (previousAttrs.postInstall or "")
      + ''
        cp $src/themes.gitconfig $out/share
      '';
  });
}
