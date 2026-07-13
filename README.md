# nightowl
Repo for various tinkering projects and home automation stuff, plus fooling around with nix on my systems.

This repo is a nix flake that also contains some homelab ansible setups for managing vaious bits and bobs of my homelab and computers.

The structure is as follows:

```
.
├── ansible/
│   └── [ansible configs live here..]
├── dotfiles/
│   └── [dotfiles and other niceties for home-manager lives here..]
├── hosts/
│   └── [Nix host configurations live here]
├── flake.nix
├── flake.lock
├── LICENSE
└── README.md <-- You are here!
```

## macOS (nix-darwin)

Run as root:
```zsh
darwin-rebuild switch --flake .
```

## WSL (standalone home-manager)

Tested on Ubuntu 24.04 with Nix installed and flakes enabled
(`experimental-features = nix-command flakes` in `~/.config/nix/nix.conf`
or `/etc/nix/nix.conf`). There's no nix-darwin/NixOS layer on WSL, so this
uses home-manager standalone instead:

```zsh
nix run home-manager/master -- switch --flake .#jerixen@wsl
```

Once home-manager is installed, subsequent runs can use:
```zsh
home-manager switch --flake .#jerixen@wsl
```

## Proxmox LXCs (NixOS)

Both LXC hosts share [hosts/common/lxc-common.nix](hosts/common/lxc-common.nix)
for the base container setup (the `jerixen` user/SSH key, sudo password,
container-specific systemd tweaks). Deploys are driven from a Mac via
`nixos-rebuild --target-host`/`--build-host` (your Mac can't cross-build
`x86_64-linux`) - see each host's `Setup.md` for the full first-time
bootstrap walkthrough:

- `nixosConfigurations.proxy` - Caddy reverse proxy.
  [hosts/proxy/Setup.md](hosts/proxy/Setup.md) /
  [hosts/proxy/configuration.nix](hosts/proxy/configuration.nix)
- `nixosConfigurations.hugin` - AdGuard Home + Unbound as the local
  network's DNS resolver.
  [hosts/hugin/Setup.md](hosts/hugin/Setup.md) /
  [hosts/hugin/configuration.nix](hosts/hugin/configuration.nix)

SSH in as `jerixen` (key-based only; root login and password auth are
disabled after the first switch).
