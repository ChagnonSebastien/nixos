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
    permittedInsecurePackages = [];
  };

  programs.nix-ld.enable = true;

  time.timeZone = "America/Montreal";
  i18n.defaultLocale = "en_US.UTF-8";

  users.defaultUserShell = pkgs.zsh;

}
