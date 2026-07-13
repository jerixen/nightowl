{ pkgs, ... }:
{
  networking.hostName = "proxy";

  # Static IP - overrides the DHCP default from lxc-common.nix.
  # "eth0" is Proxmox's usual interface name for an LXC's veth; verify with
  # `ip -o link show` over SSH first if this doesn't take effect.
  networking.useDHCP = false;
  networking.interfaces.eth0.ipv4.addresses = [
    {
      address = "10.1.50.4";
      prefixLength = 24;
    }
  ];
  networking.defaultGateway = "10.1.50.1";
  networking.nameservers = [ "1.1.1.1" "9.9.9.9" ];

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  services.caddy = {
    enable = true;

    # Cloudflare DNS-01 challenges need a caddy build with the
    # caddy-dns/cloudflare plugin - stock nixpkgs caddy doesn't include it.
    package = pkgs.caddy.withPlugins {
      plugins = [ "github.com/caddy-dns/cloudflare@v0.2.4" ];
      # The first build will fail with a hash mismatch; paste the "got:
      # sha256-..." value from that error here. Check
      # https://github.com/caddy-dns/cloudflare/tags for newer plugin tags.
      hash = "sha256-hEHgAG0F0ozHRAPuxEqLyTATBrE+pajeXDiSNwniorg=";
    };

    virtualHosts."proxmox.rdk.erixen.info".extraConfig = ''
      reverse_proxy https://10.1.1.14:8006 {
        transport http {
          tls_insecure_skip_verify
        }
      }
      tls {
        dns cloudflare {env.CLOUDFLARE_API_TOKEN}
      }
    '';

    virtualHosts."homeassistant.rdk.erixen.info".extraConfig = ''
      reverse_proxy http://10.1.107.6:8123
      tls {
        dns cloudflare {env.CLOUDFLARE_API_TOKEN}
      }
    '';

    virtualHosts."adguard.rdk.erixen.info".extraConfig = ''
      reverse_proxy http://10.1.50.11:80
      tls {
        dns cloudflare {env.CLOUDFLARE_API_TOKEN}
      }
    '';
  };

  # Keep the Cloudflare token out of the nix store/git: create this file by
  # hand on the host (root:root, mode 600) with one line:
  #   CLOUDFLARE_API_TOKEN=your-token-here
  systemd.services.caddy.serviceConfig.EnvironmentFile = "/etc/caddy/cloudflare.env";
}
