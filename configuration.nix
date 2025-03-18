{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    <home-manager/nixos>
    ./home.nix
  ];

  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 10;
  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    useOSProber = true;
    default = 0;
  };
  boot.kernelParams = [ "nvidia-drm.fbdev=1"];

  networking.hostName = "DesktopL";
  networking.networkmanager.enable = true;
  networking.firewall = {
    enable = true;
    checkReversePath = false;
    allowedUDPPorts = [ 51820 ];
    allowedTCPPorts = [ ];
  };

  time.timeZone = "America/Montreal";

  i18n.defaultLocale = "en_US.UTF-8";

  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  fonts.enableDefaultPackages = true;
  fonts.packages = with pkgs; [
    ubuntu_font_family
    liberation_ttf
    vazir-fonts
    font-awesome
    nerd-fonts.fira-code
  ];
  fonts.fontconfig = {
    defaultFonts = {
      serif = [  "Liberation Serif" "Vazirmatn" ];
      sansSerif = [ "Ubuntu" "Vazirmatn" ];
      monospace = [ "FiraCode" ];
    };
  };

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [
  ];

  hardware.graphics.enable = true;
  hardware.nvidia-container-toolkit.enable = true;
  services.xserver.videoDrivers = ["nvidia"];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    forceFullCompositionPipeline = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.vulkan_beta;
    open = false;
  };

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --remember-session";
	user = "greeter";
      };
    };
    restart = true;
  };

  systemd.services.greetd.serviceConfig = {
    Type = "idle";
    StandardInput = "tty";
    StandardOutput = "tty";
    StandardError = "journal"; # Without this errors will spam on screen
    # Without these bootlogs will spam on screen
    TTYReset = true;
    TTYVHangup = true;
    TTYVTDisallocate = true;
  };

  services.xserver.xkb.layout = "ca";
  services.xserver.xkb.variant = "fr";

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.seatd.enable = true;

  virtualisation.docker = {
    enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  users.users.seb = {
    isNormalUser = true;
    extraGroups = [ "wheel" "seat" "video" "input" "audio" "networkmanager" "docker" ];
    initialPassword = "change-me";
  };
  users.defaultUserShell = pkgs.zsh;

  environment.systemPackages = with pkgs; [
    kdePackages.dolphin
    kdePackages.breeze-icons
    spacedrive
    seatd
    kitty
    pciutils
    wget
    tree
    pavucontrol
    swaynotificationcenter # Notification daemon 
    playerctl
    ntfs3g
    cudatoolkit
  ];

  programs.nix-ld.enable = true;

  programs = {
    zsh = {
      enable = true;
      ohMyZsh = {
        enable = true;
        theme = "robbyrussell";
        plugins = [ "git" "fzf" ]; 
      };
      histSize = 5000;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;
    };
    git.enable = true;
    vim.enable = true;
    neovim.enable = true;
    fzf = {
      fuzzyCompletion = true;
      keybindings = true;
    };
  };

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
  };

  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  environment.variables = {
    XDG_SESSION_TYPE = "wayland";
    XDG_RUNTIME_DIR = "/run/user/$(id -u)";
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
  };

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.05"; # Did you read the comment?

}

