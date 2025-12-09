{
  imports = [
    ./generic.nix
    ./modules/nvidia-gpu.nix
    ./modules/shell.nix
    ./modules/docker-rootless.nix
    ./desktop-envionment/shared.nix
    ./desktop-envionment/hyprland.nix
  ];

  networking = {
    hostName = "DesktopL";
    networkmanager.enable = true;
    firewall = {
      enable = true;
      checkReversePath = false;
      allowedUDPPorts = [ 51820 ];
      allowedTCPPorts = [ ];
    };
  };

  virtualisation.docker = {
    enable = false;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  users = {
    users.seb = {
      isNormalUser = true;
      extraGroups = [ "wheel" "seat" "video" "input" "audio" "networkmanager" "docker" "vboxusers" ];
      initialPassword = "change-me";
    };
  };

  environment.systemPackages = with pkgs; [
  ];

  environment.sessionVariables = {
  };

  environment.variables = {
  };

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  system.stateVersion = "24.05"; # Did you read the comment?

}

