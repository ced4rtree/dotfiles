{ config, pkgs, ... }: {
  programs.zsh.enable = true;
  environment.shells = [ pkgs.zsh ];
  users.users.cedar.shell = pkgs.zsh;

  environment.sessionVariables = {
    ZDOTDIR = "$HOME/.config/zsh/";
  };
}
