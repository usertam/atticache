{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    systems.url = "github:usertam/nix-systems";
    attic.url = "github:zhaofengli/attic";
  };

  outputs = { self, nixpkgs, systems, ... }@inputs: let
    forAllSystems = with nixpkgs.lib; genAttrs systems.systems;
    forAllPkgs = pkgsWith: forAllSystems (system: pkgsWith nixpkgs.legacyPackages.${system});
  in {
    packages = forAllPkgs (pkgs: rec {
      inherit (inputs.attic.packages.${pkgs.system})
        attic
        attic-client
        attic-server;

      attic-server-image = pkgs.dockerTools.buildImage {
        name = "attic-server";
        tag = "main";
        copyToRoot = [
          attic-server
          pkgs.bashInteractive
          pkgs.dockerTools.caCertificates
          pkgs.dockerTools.fakeNss
        ];

        config = {
          Entrypoint = [ "${attic-server}/bin/atticd" ];
          Cmd = [ "--config" ./server.toml "--mode" "api-server" ];
          ExposedPorts."8080/tcp" = {};
        };
      };
    });
  };
}
