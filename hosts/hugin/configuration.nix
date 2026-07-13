{ ... }:
{
  imports = [ ../common/adguard-unbound.nix ];

  networking.hostName = "hugin";

  # Static IP - overrides the DHCP default from lxc-common.nix.
  # "eth0" is Proxmox's usual interface name for an LXC's veth; verify with
  # `ip -o link show` over SSH first if this doesn't take effect.
  networking.useDHCP = false;
  networking.interfaces.eth0.ipv4.addresses = [
    {
      address = "10.1.50.11";
      prefixLength = 24;
    }
  ];
  networking.defaultGateway = "10.1.50.1";
  networking.nameservers = [ "1.1.1.1" "9.9.9.9" ];

}
