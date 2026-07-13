# Standing up `proxy` for the first time

`nixosConfigurations.proxy` ([flake.nix](../../flake.nix)) targets an
unprivileged NixOS LXC container under Proxmox, currently running NixOS
26.05. This repo is a **private** GitHub repo, but since all of its flake
inputs (nixpkgs, home-manager, nix-darwin, homebrew-*) are public, the whole
first deploy can be driven from a Mac with this repo already cloned - the
container itself never needs GitHub credentials.

## Prerequisites

- An empty NixOS 26.05 LXC container already created in Proxmox, with
  networking up (DHCP) and root SSH reachable. Find its IP via the Proxmox
  web UI or `pct exec <vmid> -- ip a` on the Proxmox host.
- This repo cloned locally on a machine that can build `x86_64-linux`
  derivations or reach the container to build remotely (a Mac works via
  `--build-host`, see below).

## 1. Create the sudo password on the container

[hosts/common/lxc-common.nix](../common/lxc-common.nix) reads the `jerixen`
account password from `/etc/nixos-secrets/jerixen-password` rather than
baking a hash into git/the nix store. Set it now, over SSH as root:

```zsh
ssh root@<container-ip> 'mkdir -p /etc/nixos-secrets'
mkpasswd -m yescrypt | ssh root@<container-ip> \
  'cat > /etc/nixos-secrets/jerixen-password && chmod 600 /etc/nixos-secrets/jerixen-password'
```

(`mkpasswd` comes from nixpkgs; `nix run nixpkgs#mkpasswd` works if it's not
already installed locally.)

## 2. Create the Cloudflare API token file on the container

[hosts/proxy/configuration.nix](configuration.nix) reads the Cloudflare
DNS-01 token from `/etc/caddy/cloudflare.env`, also kept out of git/the
store:

```zsh
ssh root@<container-ip> 'mkdir -p /etc/caddy'
ssh root@<container-ip> 'tee /etc/caddy/cloudflare.env >/dev/null && chmod 600 /etc/caddy/cloudflare.env' <<'EOF'
CLOUDFLARE_API_TOKEN=your-token-here
EOF
```

## 3. Deploy from your Mac

`nixos-rebuild` isn't preinstalled on macOS - run it via `nix run`:

```zsh
nix run --extra-experimental-features 'nix-command flakes' nixpkgs#nixos-rebuild -- switch \
  --flake .#proxy \
  --target-host root@<container-ip> \
  --build-host root@<container-ip> \
  --elevate=sudo --ask-elevate-password
```

- `--build-host` is required: your Mac (aarch64-darwin) can't cross-build
  `x86_64-linux`, so the build has to happen on the container itself.
- Root SSH is required for this *first* run only - the config disables root
  login and password auth and switches to key-based `jerixen` access, which
  doesn't exist until after this first switch succeeds.

### Expect one hash-mismatch build failure

`services.caddy.package` in [configuration.nix](configuration.nix) builds
Caddy with the `caddy-dns/cloudflare` plugin via `pkgs.caddy.withPlugins`,
which is a fixed-output derivation. If its `hash` value goes stale (e.g.
after bumping the plugin's `@vX.Y.Z` tag), the build fails with:

```
error: hash mismatch in fixed-output derivation '...caddy-src-with-plugins-....drv':
         specified: sha256-...
            got:    sha256-<the real one>
```

Copy the `got:` value into `hash = "..."` in configuration.nix and re-run
the same deploy command.

## After the first switch

- Root SSH login and password auth are now disabled. Confirm `jerixen` +
  your SSH key works before closing any existing root session.
- Sudo requires the password set in step 1.
- If something's wrong and you're locked out over SSH, `pct enter <vmid>`
  from the Proxmox host gives a root console directly inside the
  container, bypassing SSH/network entirely.
- Later deploys are the same `nixos-rebuild switch` command from your Mac,
  or run `sudo nixos-rebuild switch --flake .#proxy` directly on the box as
  `jerixen`.
