{ lib, ... }:
{
  # This is an unprivileged LXC container managed by Proxmox, not a NixOS
  # "declarative container" - `boot.isContainer` tells NixOS not to expect
  # a bootloader/kernel of its own (Proxmox supplies both).
  boot.isContainer = true;

  # These upstream systemd units aren't gated by `boot.isContainer` and try
  # to mount debugfs/tracefs, which Proxmox's unprivileged LXC layer denies -
  # left unsuppressed, every switch reports a failed unit even though
  # activation otherwise succeeds.
  systemd.suppressedSystemUnits = [
    "sys-kernel-debug.mount"
    "sys-kernel-tracing.mount"
  ];

  # `nixos-generators -f proxmox-lxc` ships /sbin/init as a static copy of
  # the bootstrap image's stage-2 script, with that generation's store path
  # hardcoded inline - nixos-rebuild switch never rewrites it, so a full
  # container restart re-execs the *original* image instead of the latest
  # generation (silently reverting users, sshd config, everything). Re-point
  # it at the profile symlink on every activation so it keeps following
  # whatever's actually current.
  system.activationScripts.fixContainerInit = ''
    ln -sfn /nix/var/nix/profiles/system/init /sbin/init
  '';

  networking.useDHCP = lib.mkDefault true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  users.users.jerixen = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOzBM4HWTwLn7Toeetj0KA1kNmZOQeZN4eANvVDR3hRN jerixen@tjuppetutt"
    ];
    # Generate with `mkpasswd -m yescrypt` and put the resulting hash in this
    # file (root:root, mode 600) on the host - never commit the hash to git.
    hashedPasswordFile = "/etc/nixos-secrets/jerixen-password";
  };


  # services.openssh.openFirewall defaults to true, so port 22 is already
  # open - host-specific ports (e.g. 80/443 for a reverse proxy) belong in
  # that host's own configuration.nix.

  system.stateVersion = "26.05";
}
