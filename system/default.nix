{ inputs, ... }:
/*
  `nixosConfigurations` is sourced dynamically from
  the content of `./hosts`. Non-directory files are
  ignored. Each directory corresponds to a host
  machine, where its name is the hostname of such
  machine. `default.nix` in such directory is what
  is imported for that host build. Add or remove as
  needed.
*/
let
  inherit (builtins) readDir;
  inherit (inputs.nixpkgs.lib) nixosSystem;
  inherit (inputs.nixpkgs.lib.attrsets) filterAttrs mapAttrs;
  inherit (inputs.nixpkgs.lib.trivial) pipe;
in
{
  flake.nixosConfigurations = pipe (readDir ./hosts) [
    # Ignore non-directories. This is works fine for
    # something as simple as this. No need to
    # overcomplicate it with handling for other types.
    (filterAttrs (_: type: type == "directory"))
    # `specialArgs` and `modules` here are standard for
    # all hosts. If a specific host needs other module
    # imports, that can simply be done somewhere in the
    # host module by adding such imports to `imports`.
    # In the same manner, if a host wants to propagate
    # "special args" other than `inputs` (which has
    # everything; you would just need to source it from
    # the corresponding input), do that by adding such
    # args to `_module.args` somewhere in the host
    # module. You'll then be able to access such values
    # through the module parameters like you can with
    # `specialArgs` values, even if you declared the
    # value in the same module that references it. It
    # works. Recursive magic 🪄.
    # Example:
    # ```nix
    #  { someArg, someRecursiveMagic, ... }:
    #  {
    #    imports = [
    #      someModuleImport
    #    ];
    #
    #    _module.args = {
    #      someArg = "someValue";
    #      someRecursiveMagic = someArg;
    #    };
    #
    #    environment.sessionVariables = {
    #      SAMPLE = someRecursiveMagic;
    #    };
    #  }
    # ```
    (mapAttrs (
      name: _:
      nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          # String interpolation is "eager", which causes
          # the path's contents to be copied into the Nix
          # store separately from the rest of the flake
          # source, which is redundant, even if it does work.
          # When using path addition, the joined path will
          # reference the subpath in the flake source in the
          # Nix store instead, which is better, hence why we
          # use it here.
          (./hosts + "/${name}")
          ./shared
          ../home
          # Set `networking.hostName` to `name` since that is
          # generally the intent. If a machine really needs to
          # have the hostname set to something different, that
          # can be done in the host module by setting
          # `networking.hostName` with `lib.mkForce` to override
          # this and bypass the conflict.
          ({
            networking.hostName = name;
            # Ensure location context for this module points here.
            # This ensures that errors involving this module point
            # here as the origin in the stack trace. We manually
            # set that context through `_file`. This has the same
            # effect as using
            # `lib.modules.setDefaultModuleLocation ./.`,
            # but this is a bit nicer to read.
            _file = ./.;
          })
        ];
      }
    ))
  ];
}
