{ pkgs, ... }:
{
  # Home-manager settings shared between every machine (darwin and WSL).
  xdg.enable = true;
  xdg.configFile."starship.toml".source = ../../dotfiles/starship.toml;

  home.file.".zsh_aliases".source = ../../dotfiles/zsh-aliases;
  home.file.".gitconfig".source = ../../dotfiles/gitconfig;

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
}
