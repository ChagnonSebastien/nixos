{ pkgs, ... }:

{
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

  users.defaultUserShell = pkgs.zsh;

}
