{ pkgs, ... }:

{
  # zsh is the login shell everywhere. Everything else (plugins, prompt,
  # completion, fzf) lives in home/modules/shell.nix.
  users.defaultUserShell = pkgs.zsh;

  programs.zsh = {
    # Required because zsh is the default login shell.
    enable = true;
    # compinit runs in home-manager's zsh config, so skip it here.
    enableCompletion = false;
    promptInit = ""; # oh-my-posh (home-manager) owns the prompt
  };

  # Lets home-manager's zsh complete commands from system packages.
  environment.pathsToLink = [ "/share/zsh" ];
}
