{ buildPackage, lib }:

buildPackage {
  pname = "rtrlab-fishy-server";
  version = "0.1.0";

  src = ./.;

  cargoSha256 = lib.fakeSha256;

  nativeBuildInputs = [ ];
  buildInputs = [ ];
}
