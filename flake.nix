{
  description = "rtrlab nix flake";
  inputs = {
    nixpkgs.url = "github:/nixos/nixpkgs/nixos-25.05";
    naersk = {
      url = "github:nix-community/naersk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fenix = {
      url = "github:nix-community/fenix";
    };
  };

  outputs = {self, nixpkgs, naersk, fenix}:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      toolchain = with fenix.packages.${system}; combine [
        latest.cargo
        latest.rustc
      ];

      package = pkgs.callPackage ./derivation.nix {
        buildPackage = (naersk.lib.${system}.override {
          cargo = toolchain;
          rustc = toolchain;
        }).buildPackage;
      };
    in
    {
      nixosModules = rec {
        rtrlab = import ./modules/rtrlab;
        default = rtrlab;
      };

      overlays = rec {
        rtrlab = _final: prev: {
          inherit (self.packages.${prev.system})
            rtrlab;
        };
        default = rtrlab;
      };

      packages."x86_64-linux".rtrlab = package;
    };
}
