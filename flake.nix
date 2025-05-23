{
  inputs = {
    systems.url = "github:nix-systems/default";
    flake-parts.url = "github:hercules-ci/flake-parts";

    nixpkgs.url = "nixpkgs/nixos-25.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:nixos/nixos-hardware";
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs = {
        systems.follows = "systems";
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
        darwin.follows = "";
      };
    };

    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ ./system ];

      systems = import inputs.systems;

      perSystem =
        {
          lib,
          pkgs,
          system,
          ...
        }:
        let
          treefmt =
            (inputs.treefmt-nix.lib.evalModule pkgs {
              projectRootFile = "flake.lock";
              programs.nixfmt.enable = true;
            }).config.build.wrapper;

          pre-commit = inputs.pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks.treefmt = {
              enable = true;
              package = treefmt;
              pass_filenames = false;
            };
          };
        in
        {
          checks.pre-commit = pre-commit;
          formatter = treefmt;
          devShells.default = pkgs.mkShellNoCC {
            inherit (pre-commit) shellHook;
            packages = [
              pkgs.git
              pkgs.nil
            ];
          };
        };
    };
}
