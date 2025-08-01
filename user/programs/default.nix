{ config, lib, pkgs, ... }: {
  imports = [
    ./batsignal.nix
    ./direnv.nix
    ./homestuck.nix
    ./mako.nix
    ./virt-manager.nix
    ./xdg.nix
    ./qutebrowser.nix
    ./mpris.nix
    ./gpg.nix
    ./vesktop.nix
    ./hypridle.nix
    ./hyprlock.nix
    ./hyprpaper.nix
    # ./mpd.nix
  ];
}
