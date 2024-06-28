{ config, pkgs, ... }: {
  home.packages = with pkgs; [
    hyprland
    rofi-wayland-unwrapped
    waybar
    wl-clipboard
    foot
    wlr-randr
    swaybg
    egl-wayland
  ];

  wayland.windowManager.hyprland.xwayland.enable = true;
}
