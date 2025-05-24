{ lib, ... }:
let
  inherit (lib.attrsets) attrValues;
  inherit (lib.lists) flatten;

  groups = {
    # This is the standard user group to give users root privileges.
    # Nothing special here.
    admin = [ "wheel" ];
    # Ensure access to adjust display brightness. Brillo uses this.
    display = [ "video" ];
    # <https://nixos.org/manual/nixos/stable/#sec-networkmanager>
    # <https://github.com/NixOS/nixpkgs/issues/222943>
    # <https://github.com/NixOS/nixpkgs/blob/nixos-22.11/nixos/modules/services/networking/networkmanager.nix#L73-L82>
    # ----------------------------------------------------------------------------------------------------------------
    # Ensure proper access to change network settings. This is a non-standard
    # NixOS-specific group. Normally users do not require root access nor to
    # be part of any special user group to change network settings, such as on
    # Arch Linux. In NixOS however, the `networking.networkmanager.enable`
    # option adds a Polkit rule to only allow those in this group access.
    networking = [ "networkmanager" ];
    # <https://wiki.nixos.org/wiki/Scanners>
    # <https://github.com/NixOS/nixpkgs/blob/nixos-22.11/nixos/modules/services/hardware/sane.nix#L55>
    # ------------------------------------------------------------------------------------------------
    # Ensure proper access to printers and scanners. CUPS does not appear to
    # need this, but these are used by SANE for scanner/printer access.
    printScan = [
      "lp"
      "scanner"
    ];
  };
in
{
  users = {
    # It would be great to have this set to `false`
    # to have almost everything be declarative, but
    # that would require secrets handling (passwords)
    # which is a pain since this repo is public. I
    # could have a flake input that is a private repo
    # that contains age-encrypted password files for
    # use with `agenix`, but that would then require
    # setting up authentication keys for new systems
    # to be able to fetch the secrets flake, which is
    # also annoying. So a bit of declarative magic is
    # sacrificed here to remove the hassle altogether.
    # I will re-visit this concern in the future.
    mutableUsers = true;

    users = {
      sebas = {
        isNormalUser = true;
        uid = 1000;
        extraGroups = flatten (attrValues groups);
      };
    };
  };
}
