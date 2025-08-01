{ config, lib, pkgs, ... }: {
  hardware.graphics = {
    enable = true;
    # driSupport = true;
    enable32Bit = true;
    # driSupport32Bit = true;
  };

  # programs.xwayland.enable = true;

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    powerManagement = {
      enable = false;
      finegrained = false;
    };
    nvidiaSettings = true;

    prime = {
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";

      offload.enable = true;
    };
  };
}
