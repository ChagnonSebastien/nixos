{ ... }:

{
  # Every host, including the minimal ones built without mkHost (vps, homelab-rescue).
  nix = {
    settings.experimental-features = [ "nix-command" "flakes" ];
    settings.auto-optimise-store = true;
    # every deploy adds a generation; without this the store only ever grows
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  time.timeZone = "America/Montreal";
}
