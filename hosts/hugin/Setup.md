# Standing up `hugin` for the first time

`nixosConfigurations.hugin` ([flake.nix](../../flake.nix)) targets an
unprivileged NixOS LXC container under Proxmox running AdGuard Home (LAN
DNS + ad/tracker blocking) with Unbound behind it for recursive resolution.
It shares the same base as [proxy](../proxy/Setup.md) -
[hosts/common/lxc-common.nix](../common/lxc-common.nix) - for the `jerixen`
user, SSH key, sudo password, and container-specific systemd tweaks.

## Prerequisites

- An empty NixOS 26.05 LXC container already created in Proxmox, with
  networking up (DHCP) and root SSH reachable. Find its IP via the Proxmox
  web UI or `pct exec <vmid> -- ip a` on the Proxmox host.
- This repo cloned locally.

## 1. Create the sudo password on the container

Same mechanism as `proxy`: [hosts/common/lxc-common.nix](../common/lxc-common.nix)
reads the `jerixen` account password from `/etc/nixos-secrets/jerixen-password`
rather than baking a hash into git/the nix store.

```zsh
ssh root@<container-ip> 'mkdir -p /etc/nixos-secrets'
mkpasswd -m yescrypt | ssh root@<container-ip> \
  'cat > /etc/nixos-secrets/jerixen-password && chmod 600 /etc/nixos-secrets/jerixen-password'
```

## 2. Deploy from your Mac

```zsh
nix run --extra-experimental-features 'nix-command flakes' nixpkgs#nixos-rebuild -- switch \
  --flake .#hugin \
  --target-host root@<container-ip> \
  --build-host root@<container-ip> \
  --elevate=sudo --ask-elevate-password
```

- `--build-host` is required: your Mac (aarch64-darwin) can't cross-build
  `x86_64-linux`, so the build has to happen on the container itself.
- Root SSH is required for this *first* run only - the config disables root
  login and password auth and switches to key-based `jerixen` access, which
  doesn't exist until after this first switch succeeds.

## 3. Create the AdGuard Home admin account

[hosts/common/adguard-unbound.nix](../common/adguard-unbound.nix) (imported
by [configuration.nix](configuration.nix)) declares AdGuard Home's DNS
settings, filters, and rewrites - extracted from this host's own live
config after its first manual setup wizard run. `users` (the admin login,
bcrypt hash included) is deliberately left out of that declarative block so
it never ends up in git; `mutableSettings` (the module default) merges the
declared settings into each host's on-disk config on every start rather
than replacing it, so the account you create here persists across deploys.

1. Browse to `http://<container-ip>:80` (or whatever port
   `services.adguardhome.port` is set to) and create the admin account.
   Since DNS/filters/rewrites are already declared, the wizard should have
   little left to ask beyond the login itself.
2. **If you change `services.adguardhome.port`**, redeploy - `port` is what
   drives `openFirewall`, so a mismatch means the firewall blocks whatever
   port AdGuard Home actually bound to.
3. Point your router/DHCP server (or individual clients) at `<container-ip>`
   for DNS.

Since the declared config in `adguard-unbound.nix` is shared with every
host that imports it (see [munin](../munin/Setup.md)), DNS rewrites like
the `rdk.erixen.info` split-horizon entries below apply identically on all
of them - edit that one file rather than each host's web UI.

`rdk.erixen.info` has real public DNS (used for the Cloudflare DNS-01
challenges on `proxy`), so without a local override, LAN clients would
hairpin out through the router and back in to reach it. The declared
`filtering.rewrites` entries override that for LAN clients while external
visitors still get the real public answer - a split-horizon setup with no
extra DNS software. AGH matches the most specific rule first *for entries
of the same answer type* - so the `proxmox.rdk.erixen.info`/
`homeassistant.rdk.erixen.info` exact-match entries win over the
`*.rdk.erixen.info` wildcard (which defaults to `citadel`, since it hosts
most services) only because the wildcard's answer is `citadel`'s IP, not
its hostname. A hostname answer makes AGH treat that rewrite as a CNAME
internally, and AGH's rewrite-priority sort always ranks CNAME entries
above plain A/AAAA ones regardless of exact-vs-wildcard specificity - so a
hostname-answer wildcard would shadow every exact-match entry above it
instead of losing to them. Keep the wildcard's answer as an IP. Add a new
exact-match entry whenever a service on `proxy` doesn't yet exist, or
remove one if that service ever moves to `citadel` instead.

## After the first switch

- Root SSH login and password auth are now disabled. Confirm `jerixen` +
  your SSH key works before closing any existing root session.
- Sudo requires the password set in step 1.
- If something's wrong and you're locked out over SSH, `pct enter <vmid>`
  from the Proxmox host gives a root console directly inside the
  container, bypassing SSH/network entirely.
- Later deploys are the same `nixos-rebuild switch` command from your Mac,
  or run `sudo nixos-rebuild switch --flake .#hugin` directly on the box as
  `jerixen`.

