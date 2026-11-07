{ lib, ... }:

let
  # Lists fed to pi-hole as file:// adlists, kept as plain text next to
  # this module: <name>.txt -> ~/.config/pihole-lists/<name>.txt
  # Deny lists register with adlist type 0, allow/ lists with type 1 (antigravity).
  lists = [
    "general"
    "allow/tv"
    "allow/phone"
    "allow/guest"
    "allow/work"
    "allow/desktop"
  ];
in {
  xdg.configFile = lib.listToAttrs (map (name:
    lib.nameValuePair "pihole-lists/${name}.txt" {
      text = builtins.readFile (./. + "/${name}.txt");
    }) lists);
}
