{ ... }:
{
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    # If enabled, users must be in the
    # `podman` group to connect to it,
    # but with the same concern that
    # such members gain root access
    # equivalency, just like with
    # Docker.
    dockerSocket.enable = false;
  };
}
