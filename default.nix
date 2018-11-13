{ mkDerivation, base, base-prelude, docker, stdenv, text}:
mkDerivation {
  pname = "dockerdns-hask";
  version = "0.1.0.0";
  src = ./.;
  isLibrary = false;
  isExecutable = true;
  executableHaskellDepends = [ base base-prelude docker text];
  license = stdenv.lib.licenses.mit;
}
