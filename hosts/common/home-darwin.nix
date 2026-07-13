{ ... }:
{
  # Darwin-only home-manager settings. Packages like starship and
  # zsh-autosuggestions are installed via homebrew (see darwin-common.nix),
  # so mac-dot-zshrc sources them from the brew prefix.
  home.file.".zshrc".source = ../../dotfiles/mac-dot-zshrc;
}
