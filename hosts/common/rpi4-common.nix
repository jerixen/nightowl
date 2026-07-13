{ lib, ... }:
{
  # Bare-metal SBC, not a Proxmox-supplied container - this host
  # owns its own bootloader and kernel. `raspberry-pi-4` (wired up
  # in flake.nix from the nixos-hardware input) supplies RPi4 firmware,
  # device-tree and kernel handling; `generic-extlinux-compatible` is the
  # usual bootloader for that setup. If this box was installed some other
  # way (e.g. a UEFI firmware image instead of U-Boot/extlinux), check its
  # existing boot loader settings before assuming this matches.
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;
  boot.loader.timeout = 5;

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
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOzBM4HWTwLn7Toeetj0KA1kNmZOQeZN4eANvVDR3hRN jerixen"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM1pf9cxPH2BblbzUd298DJJXfkpZBpws6wQIPcMicDq jerixen@blackbox"
    ];
    # Generate with `mkpasswd -m yescrypt` and put the resulting hash in this
    # file (root:root, mode 600) on the host - never commit the hash to git.
    hashedPasswordFile = "/etc/nixos-secrets/jerixen-password";
  };

  # services.openssh.openFirewall defaults to true, so port 22 is already
  # open - host-specific ports belong in that host's own configuration.nix.

  # NOTE: stateVersion should match whatever this SBC's filesystem was
  # originally created with, not necessarily the repo's current nixpkgs
  # channel - verify against the existing install's configuration.nix
  # before changing this.
  system.stateVersion = "26.05";
}
