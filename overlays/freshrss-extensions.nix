final: prev: {
  freshrssExtensions = final.callPackage ../pkgs/freshrss-extensions {
    inherit (prev) config;
  };
}
