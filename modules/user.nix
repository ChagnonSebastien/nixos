{ ... }:

{
  # User seb on bare-metal machines. Hosts add their own extra groups.
  # (WSL gets its user from NixOS-WSL's wsl.defaultUser instead.)
  users.users.seb = {
    isNormalUser = true;
    extraGroups = [ "wheel" "seat" "video" "input" "audio" "networkmanager" ];
    # Only used when the account is first created.
    initialPassword = "change-me";
  };
}
