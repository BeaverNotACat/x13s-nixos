{
  description = "NixOS flake build";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    mobile-nixos = {
      url = "github:NixOS/mobile-nixos/master";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, mobile-nixos }: {
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
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
      };
    };
  };
}
