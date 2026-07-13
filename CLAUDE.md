# nightowl

Homelab monorepo for jerixen's infrastructure. Contains Nix configurations (nix-darwin, NixOS, home-manager) and Ansible playbooks for Proxmox nodes.

## Repo layout

```
flake.nix                  # Single flake entry point for all systems
hosts/
  common/                  # Shared modules imported by multiple hosts
    darwin-common.nix      # Mac packages, homebrew, macOS defaults
    darwin-common-dock.nix # Dock layout
    home-common.nix        # Shared home-manager config (all platforms)
    home-darwin.nix        # home-manager additions for darwin
    home-wsl.nix           # home-manager additions for WSL
    nixos-common.nix       # Shared NixOS config: zsh, tmux, tailscale, CLI tools
    lxc-common.nix         # Unprivileged Proxmox LXC baseline
    rpi4-common.nix        # Raspberry Pi 4 baseline
    adguard-unbound.nix    # AdGuard Home + Unbound (shared by hugin and munin)
  proxy/configuration.nix  # Caddy reverse proxy LXC (10.1.50.4)
  hugin/configuration.nix  # AdGuard + Unbound DNS LXC (10.1.50.11)
  munin/configuration.nix  # AdGuard + Unbound DNS RPi4 (10.1.50.12)
dotfiles/                  # Dotfiles sourced directly by nix modules
ansible/                   # Ansible for Proxmox bare-metal nodes
```

## Nix inputs

Three nixpkgs pins are intentional:
- `nixpkgs` (nixos-26.05) — used for all NixOS hosts
- `nixpkgs-unstable` — used for the WSL home-manager config
- `nixpkgs-darwin` (nixpkgs-unstable) — used for the darwin config and home-manager on darwin

## Hosts

| Flake output | Hostname | Platform | Role |
|---|---|---|---|
| `darwinConfigurations.tjuppetutt` | tjuppetutt | aarch64-darwin | Personal MacBook |
| `homeConfigurations.jerixen@wsl` | — | x86_64-linux | WSL on Ubuntu 24.04 |
| `nixosConfigurations.proxy` | proxy | x86_64-linux LXC | Caddy reverse proxy |
| `nixosConfigurations.hugin` | hugin | x86_64-linux LXC | Primary DNS (AdGuard + Unbound) |
| `nixosConfigurations.munin` | munin | aarch64-linux RPi4 | Secondary DNS (AdGuard + Unbound) |

## Applying configurations

**Mac (run locally on tjuppetutt):**
```sh
darwin-rebuild switch --flake .#tjuppetutt
```

**WSL (run inside WSL):**
```sh
nix run home-manager/master -- switch --flake .#jerixen@wsl
```

**NixOS hosts (run inside the container/Pi over SSH):**
```sh
sudo nixos-rebuild switch --flake .#proxy   # or hugin / munin
```

## Checking the flake

```sh
nix flake check          # evaluates all outputs; run after any .nix edit
nix flake show           # lists all outputs
```

## Dev shell (ansible)

```sh
nix develop              # enters shell with ansible, ansible-playbook, ansible-vault
```

The dev shell works on `aarch64-darwin` and `x86_64-linux`.

## Ansible

Playbooks live in `ansible/`. The `ansible.cfg` sets `inventory=hosts` and `vault_password_file=vault_pass` (gitignored). Secrets are stored in `ansible/secrets.yml` (ansible-vault encrypted).

```sh
# Run from ansible/ or with -C ansible/
ansible-playbook install_pve_nodes.yml --tags base
ansible-vault edit secrets.yml
```

Target groups: `pve_nodes` (erixen-pve, erixen-nuc-pve), `proxies`, `virtual_machines`.

## Secrets that live outside the store

- `ansible/vault_pass` — ansible-vault password file (gitignored, create by hand)
- `ansible/secrets.yml` — vault-encrypted vars (`supersecret_pass`, etc.)
- `/etc/caddy/cloudflare.env` — Cloudflare API token on the proxy host (root:root 600)
