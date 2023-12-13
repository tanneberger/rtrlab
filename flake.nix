{
  description = "rtrlab nix flake";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    microvm = {
      url = "github:astro/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    naersk = {
      url = "github:nix-community/naersk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fenix = {
      url = "github:nix-community/fenix";
    };
  };

  outputs = inputs@{ self, nixpkgs, microvm, sops-nix, naersk, fenix}: 
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
  in {
    packages."x86_64-linux".rtrlab-microvm = self.nixosConfigurations.rtrlab.config.microvm.declaredRunner;
    packages."x86_64-linux".rtrlab-fishy-server = package;
    nixosConfigurations = {
      rtrlab = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs self; };
        modules = [
          microvm.nixosModules.microvm
          sops-nix.nixosModules.sops
          ./modules/rtrlab
          ./hosts/rtrlab
          ./modules/nginx.nix
          {
            nixpkgs.overlays = [
                (final: prev: {
                inherit (self.packages.${prev.system}) rtrlab-fishy-server;
                })
            ];
          }
        ];
      };
    };
  };
}
