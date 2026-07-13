{ pkgs, lib, ... }:
{
  # Shared across all NixOS boxes (proxy, hugin, munin) - zsh as the default
  # login shell, plus the same CLI toolset used on darwin (see
  # darwin-common.nix's environment.systemPackages).
  users.defaultUserShell = pkgs.zsh;

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    # NixOS's default `prompt suse` runs after interactiveShellInit and
    # overwrites PROMPT/PS1, clobbering the one `starship init zsh` sets up.
    promptInit = "";
    # Same issue for l/ll/ls: NixOS's defaults are applied after
    # interactiveShellInit and would clobber the eza-based ones from
    # dotfiles/zsh-aliases.
    shellAliases = lib.mkForce { };
    interactiveShellInit = ''
      source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh

      . /etc/zsh_aliases

      eval "$(zoxide init --cmd cd zsh)"

      eval "$(starship init zsh)"
    '';
  };

  programs.tmux = {
    enable = true;
    plugins = with pkgs.tmuxPlugins; [
      sensible
      resurrect
      catppuccin
    ];
    extraConfig = ''
      set -g mouse on
      set -g @catppuccin_flavor 'mocha' # latte, frappe, macchiato or mocha
    '';
  };

  environment.etc."zsh_aliases".source = ../../dotfiles/zsh-aliases;
  environment.etc."starship.toml".source = ../../dotfiles/starship.toml;
  environment.variables.STARSHIP_CONFIG = "/etc/starship.toml";

  environment.systemPackages = with pkgs; [
    bat
    eza
    helix
    ripgrep
    uv
    vim
    zoxide
    fzf
    yazi
    _7zz
    gping
    starship
    zsh-autosuggestions
  ];

  # TAILSCALE
  # Tailscale in unpriviledged lxc-containers is a bit fiddley
  # https://tailscale.com/docs/features/containers/lxc/lxc-unprivileged states that a couple of lines need to be present in every LXCs config file, under /etc/pve/<containerid>
  services.tailscale = {
    # Enable tailscale at startup
    enable = true;
    useRoutingFeatures = "server";
    # If you would like to use a preauthorized key, set
    # authKeyFile = "/run/secrets/tailscale_key";
    # Note: maximum expire time is 90 days
  };
}
