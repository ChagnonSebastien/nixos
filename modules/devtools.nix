{ ... }:

{
  # System-level half of home/modules/devtools.nix. Session variables set
  # here also reach GUI apps (IDEs), not just home-manager's shells.
  environment.sessionVariables = {
    GOPRIVATE = "gitlab.com/qohash/*";
  };
}
