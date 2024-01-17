{
  description = "NixOS flake build";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    mobile-nixos = {
      url = "github:NixOS/mobile-nixos/master";
      flake = false;
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, mobile-nixos, nixos-generators }: let
    system = "aarch64-linux";
    modules = [
      ({ nixpkgs.overlays = [ 
        (final: prev: {
          qrtr = prev.callPackage "${mobile-nixos}/overlay/qrtr/qrtr.nix" {};
          qmic = prev.callPackage "${mobile-nixos}/overlay/qrtr/qmic.nix" {};
          rmtfs = prev.callPackage "${mobile-nixos}/overlay/qrtr/rmtfs.nix" {};
          pd-mapper = final.callPackage "${mobile-nixos}/overlay/qrtr/pd-mapper.nix" {inherit (final) qrtr;};
          compressfirmwarexz = nixpkgs.lib.id;
        })
      ]; })
      ./configuration.nix
    ];
  in {
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        inherit modules;
      };
    };
    packages.${system} = {
      x13s = nixos-generators.nixosGenerate {
        inherit system;
        inherit modules;
        format = "raw-efi";
      };
    };
  };
}
