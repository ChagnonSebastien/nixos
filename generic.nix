{ pkgs, ... }:

{
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

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
    };

    settings.experimental-features = [ "nix-command" "flakes" ];
  };

  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [
      "beekeeper-studio-5.3.4"
      "gradle-7.6.6"
    ];
  };

  programs.nix-ld.enable = true;

  time.timeZone = "America/Montreal";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_CA.UTF-8";
    LC_IDENTIFICATION = "en_CA.UTF-8";
    LC_MEASUREMENT = "en_CA.UTF-8";
    LC_MONETARY = "en_CA.UTF-8";
    LC_NAME = "en_CA.UTF-8";
    LC_NUMERIC = "en_CA.UTF-8";
    LC_PAPER = "en_CA.UTF-8";
    LC_TELEPHONE = "en_CA.UTF-8";
    LC_TIME = "en_CA.UTF-8";
  };

  users.defaultUserShell = pkgs.zsh;

}
