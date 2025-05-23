{
  config,
  inputs,
  lib,
  ...
}:
/*
  <https://nix-community.github.io/home-manager/index.xhtml#sec-flakes-nixos-module>
  ----------------------------------------------------------------------------------
  This is using the NixOS module approach for Home Manager rather than the standalone
  implementation. It helps keep things clean and better integrated system-wide.
  Building everything together is fine.

  `home-manager.users` is sourced dynamically from the content of `./users`.
  Non-directory files are ignored. Each directory corresponds to a user, where its
  name is the username of such user. `default.nix` in such directory is what is
  imported for that user build. Add or remove as needed.
*/
let
  inherit (builtins) readDir;
  inherit (lib.attrsets) filterAttrs mapAttrs;
  inherit (lib.trivial) pipe;
in
{
  imports = [ inputs.home-manager.nixosModules.default ];

  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    backupFileExtension = ".bak";

    extraSpecialArgs = {
      inherit inputs;
      # This is propagated to make possible tighter integration
      # with the system, such as to have a Home Manager module
      # use the exact package the system will use.
      nixosConfig = config;
    };

    users = pipe (readDir ./users) [
      # Ignore non-directories. This is works fine for
      # something as simple as this. No need to
      # overcomplicate it with handling for other types.
      (filterAttrs (_: type: type == "directory"))
      # `extraSpecialArgs` (above) and `imports` here are
      # standard for all users (which currently is just
      # `./shared`). If a specific user needs other module
      # imports, that can simply be done somewhere in the
      # user module by adding such imports to `imports`. In
      # the same manner, if a user wants to propagate
      # "special args" other than `nixosConfig` or `inputs`
      # (which has everything; you would just need to source
      # it from the corresponding input), do that by adding
      # such args to `_module.args` somewhere in the user
      # module. You'll then be able to access such values
      # through the module parameters like you can with
      # `extraSpecialArgs` values, even if you declared the
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
      #    home.sessionVariables = {
      #      SAMPLE = someRecursiveMagic;
      #    };
      #  }
      # ```
      (mapAttrs (
        name: _: {
          imports = [
            # String interpolation is "eager", which causes
            # the path's contents to be copied into the Nix
            # store separately from the rest of the flake
            # source, which is redundant, even if it does work.
            # When using path addition, the joined path will
            # reference the subpath in the flake source in the
            # Nix store instead, which is better, hence why we
            # use it here.
            (./users + "/${name}")
            ./shared
            # Set `home.username` to `name` and `home.homeDirectory`
            # to `"/home/" + config.home.username` since that is
            # generally the intent. If a user really needs to have
            # the username or home directory set to something
            # different, that can be done in the user module by
            # setting `home.username` and/or `home.homeDirectory`
            # with `lib.mkForce` to override this and bypass the
            # conflict.
            (
              { config, ... }:
              {
                home = {
                  username = name;
                  homeDirectory = "/home/" + config.home.username;
                };
                # Ensure location context for this module points here.
                # This ensures that errors involving this module point
                # here as the origin in the stack trace. We manually
                # set that context through `_file`. This has the same
                # effect as using
                # `lib.modules.setDefaultModuleLocation ./.`,
                # but this is a bit nicer to read.
                _file = ./.;
              }
            )
          ];
        }
      ))
    ];
  };
}
