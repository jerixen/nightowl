{
  description = "Configuration for systems by jerixen";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin.url = "github:lnl7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs-darwin";

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    homebrew-core = { url = "github:homebrew/homebrew-core"; flake = false; };
    homebrew-cask = { url = "github:homebrew/homebrew-cask"; flake = false; };
    homebrew-bundle = { url = "github:homebrew/homebrew-bundle"; flake = false; };

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs-darwin";

    nixos-hardware.url = "github:NixOS/nixos-hardware";
  };
  outputs = { self, ... }@inputs:
  let
    inherit (inputs) self nixpkgs nixpkgs-darwin nixpkgs-unstable home-manager;
    username = "jerixen";
    system.configurationRevision = self.rev or self.dirtyRev or null;
    system.stateVersion = 6;
    nix.settings.experimental-features = "nix-command flakes";
  in {
    darwinConfigurations.tjuppetutt = inputs.nix-darwin.lib.darwinSystem {
        modules = [
          ./hosts/common/darwin-common.nix
          ./hosts/common/darwin-common-dock.nix
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = ".bak";
            home-manager.users.${username} = {
              imports = [
                ./hosts/common/home-common.nix
                ./hosts/common/home-darwin.nix
              ];
              home.username = username;
              home.homeDirectory = "/Users/${username}";
              home.stateVersion = "26.05";
            };
          }
        ];
        system="aarch64-darwin";
      };

    # Standalone home-manager (no nix-darwin/NixOS underneath), for WSL.
    # On Ubuntu 24.04 with Nix + flakes installed, apply with:
    #   nix run home-manager/master -- switch --flake .#jerixen@wsl
    homeConfigurations."${username}@wsl" = home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs-unstable {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };
      modules = [
        ./hosts/common/home-common.nix
        ./hosts/common/home-wsl.nix
        {
          home.username = username;
          home.homeDirectory = "/home/${username}";
          home.stateVersion = "23.11";
        }
      ];
    };

    # NixOS running as an unprivileged LXC container under Proxmox.
    # Apply from within the container:
    #   sudo nixos-rebuild switch --flake .#proxy
    nixosConfigurations.proxy = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hosts/common/lxc-common.nix
        ./hosts/common/nixos-common.nix
        ./hosts/proxy/configuration.nix
      ];
    };

    # NixOS LXC running AdGuard Home (+ Unbound for recursion) as the local
    # network's DNS resolver. Apply from within the container:
    #   sudo nixos-rebuild switch --flake .#hugin
    nixosConfigurations.hugin = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hosts/common/lxc-common.nix
        ./hosts/common/nixos-common.nix
        ./hosts/hugin/configuration.nix
      ];
    };

    # NixOS on bare-metal Raspberry Pi 4 (8GB), running a second independent
    # AdGuard Home + Unbound resolver alongside hugin. Apply from the Pi:
    #   sudo nixos-rebuild switch --flake .#munin
    nixosConfigurations.munin = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        inputs.nixos-hardware.nixosModules.raspberry-pi-4
        ./hosts/common/rpi4-common.nix
        ./hosts/common/nixos-common.nix
        ./hosts/munin/configuration.nix
      ];
    };
  };
}