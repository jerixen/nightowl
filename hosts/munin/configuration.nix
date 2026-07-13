{ ... }:
{
  imports = [
    ../common/adguard-unbound.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "munin";

  # Static IP - overrides the DHCP default from rpi4-common.nix.
  # "eth0" is the RPi4's onboard ethernet under the usual naming scheme;
  # verify with `ip -o link show` over SSH first if this doesn't take effect
  # (predictable interface naming can pick something like "end0" instead).
  networking.useDHCP = false;
  networking.interfaces.eth0.ipv4.addresses = [
    {
      address = "10.1.50.12";
      prefixLength = 24;
    }
  ];
  networking.defaultGateway = "10.1.50.1";
  networking.nameservers = [ "1.1.1.1" "9.9.9.9" ];

  # Independent AdGuard Home + Unbound instance, same setup as hugin - not a
  # failover pair, just a second resolver with its own AGH state. Point some
  # clients at 10.1.50.12 instead of (or in addition to) hugin's 10.1.50.11.
}
