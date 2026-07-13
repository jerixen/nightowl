# Standing up `munin` for the first time

`nixosConfigurations.munin` ([flake.nix](../../flake.nix)) targets a
bare-metal Raspberry Pi 4 (8GB) running a second, independent AdGuard Home
(LAN DNS + ad/tracker blocking) + Unbound (recursive resolution) instance -
same [adguard-unbound.nix](../common/adguard-unbound.nix) module
[hugin](../hugin/Setup.md) uses, but not a failover pair: it's its own AGH
process/state and its own IP, and you point clients at either one
independently. DNS settings, filters, and rewrites are declared in that
shared module though, so both resolvers behave identically out of the box
- only the admin account (created via the web UI, kept out of git) is
per-host.

Unlike `hugin`/`proxy` (unprivileged LXC containers where Proxmox supplies
the kernel and bootloader - see
[hosts/common/lxc-common.nix](../common/lxc-common.nix)), `munin` is real
hardware. It gets its own base,
[hosts/common/rpi4-common.nix](../common/rpi4-common.nix), plus the
`raspberry-pi-4` module from the
[nixos-hardware](https://github.com/NixOS/nixos-hardware) flake input
(wired up directly in [flake.nix](../../flake.nix)) for RPi4 firmware/
device-tree handling.

## Prerequisites

- NixOS already installed and booting on the Pi (this doc doesn't cover
  imaging the SD card/SSD), with networking up and SSH reachable.
- This repo cloned locally.

## 1. Get the real hardware configuration

[hosts/munin/hardware-configuration.nix](hardware-configuration.nix) in
this repo is a placeholder that deliberately fails evaluation (`throw`) -
filesystem UUIDs, the SD card/SSD device, and any hardware quirks are
specific to this physical unit and can't be authored blind. On the Pi (or
from its existing install's `/etc/nixos`), run:

```zsh
nixos-generate-config --show-hardware-config
```

and replace the contents of `hosts/munin/hardware-configuration.nix` with
that output.

Also check the existing install's `boot.loader` settings against
[rpi4-common.nix](../common/rpi4-common.nix)'s
`generic-extlinux-compatible` default (the common case for a U-Boot/
extlinux RPi4 install) and its `system.stateVersion` against
`rpi4-common.nix`'s `"26.05"` - `stateVersion` should match whatever the
filesystem was originally created with, not necessarily this repo's
current nixpkgs channel.

## 2. Create the sudo password on the Pi

Same mechanism as `hugin`/`proxy`:
[hosts/common/rpi4-common.nix](../common/rpi4-common.nix) reads the
`jerixen` account password from `/etc/nixos-secrets/jerixen-password`
rather than baking a hash into git/the nix store.

```zsh
ssh <user>@<pi-ip> 'sudo mkdir -p /etc/nixos-secrets'
mkpasswd -m yescrypt | ssh <user>@<pi-ip> \
  'sudo tee /etc/nixos-secrets/jerixen-password >/dev/null && sudo chmod 600 /etc/nixos-secrets/jerixen-password'
```

## 3. Deploy from your Mac

Building on the Pi itself works but is slow, and as of mid-2026 nixpkgs
doesn't have a cached `linux-rpi` kernel build for 26.05 (Hydra isn't
building it yet), so a from-scratch kernel build can take hours - see
[this discourse thread](https://discourse.nixos.org/t/nixos-26-05-raspberry-pi-4-kernel-cache-missing/78125).

Build directly on the Pi:

```zsh
nix run --extra-experimental-features 'nix-command flakes' nixpkgs#nixos-rebuild -- switch \
  --flake .#munin \
  --target-host root@<pi-ip> \
  --build-host root@<pi-ip> \
  --elevate=sudo --ask-elevate-password
```

- `--build-host` is required either way: your Mac (aarch64-darwin) doesn't
  have a Linux builder for `aarch64-linux`.
- If hugin's `systemd-binfmt.service` fails after deploying its config
  (unprivileged LXC containers may lack the `CAP_SYS_ADMIN` needed to
  register a binfmt_misc handler themselves), install
  `qemu-user-static`/`binfmt-support` on the Proxmox host instead - the
  container shares the host's kernel, so a host-level registration is
  picked up inside it too.
- If root SSH is already disabled on the existing install, target the
  `jerixen` user (once its key is authorized) or whatever admin account is
  already set up instead of `root`.

## 4. Static IP and creating the AdGuard Home admin account

[hosts/munin/configuration.nix](configuration.nix) sets a static IP of
`10.1.50.12` on `eth0` - verify the interface name with
`ip -o link show` over SSH first if it doesn't take effect (predictable
network interface naming can pick something like `end0` instead on some
kernels/device trees).

DNS settings, filters, and rewrites come from the shared
[adguard-unbound.nix](../common/adguard-unbound.nix) module, so this
instance behaves identically to hugin's out of the box - see
[hugin/Setup.md](../hugin/Setup.md#3-create-the-adguard-home-admin-account)
for the (short) remaining wizard step: browse to `http://<pi-ip>:80` (or
whatever `services.adguardhome.port` is set to) and create the admin
account. If you want this instance's rewrites/filters to diverge from
hugin's, edit `adguard-unbound.nix` for shared changes or add
munin-specific overrides in this host's own `configuration.nix`.

## After the first switch

- Confirm `jerixen` + your SSH key works before closing any existing admin
  session on the Pi.
- Sudo requires the password set in step 2.
- Later deploys are the same `nixos-rebuild switch` command from your Mac,
  or run `sudo nixos-rebuild switch --flake .#munin` directly on the Pi.
