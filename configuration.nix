{
  imports = [
    ./generic.nix
    ./modules/shell.nix
    ./modules/desktop.nix
  ];

  boot.loader = {
    efi.canTouchEfiVariables = true;
    timeout = 10;
    grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      useOSProber = true;
      default = 0;
    };
  };

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

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  system.stateVersion = "24.05"; # Did you read the comment?

}

