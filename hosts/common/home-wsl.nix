{ pkgs, ... }:
{
  # WSL has no nix-darwin/homebrew layer to install CLI tools, so
  # home-manager owns them here instead.
  home.packages = with pkgs; [
    bat
    eza
    ripgrep
    starship
    zoxide
    zsh-autosuggestions
  ];

  home.file.".zshrc".text = ''
    source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh

    . "$HOME/.zsh_aliases"

    eval "$(starship init zsh)"
    eval "$(zoxide init zsh)"
  '';
}
