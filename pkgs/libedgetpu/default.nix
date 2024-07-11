{
  stdenv,
}:

stdenv.mkDerivation {
  src = ./libedgetpu.so.1.0;

  pname = "libedgetpu";
  version = "whatever";

  dontBuild = true;
  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/lib
    cp $src $out/lib/libedgetpu.so.1.0
    ln -s $out/lib/libedgetpu.so.1.0 $out/lib/libedgetpu.so.1
  '';
}