{ pkgs, ... }:

{
  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };

    settings.experimental-features = [ "nix-command" "flakes" ];
    settings.auto-optimise-store = true;
  };

  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [
      "beekeeper-studio-5.5.3"
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
