{ pkgs, ... }:

{
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  fonts.enableDefaultPackages = true;
  fonts.packages = with pkgs; [
    ubuntu-classic
    liberation_ttf
    (pkgs.vazirmatn or pkgs.vazir-fonts) # renamed in unstable; drop fallback once stable has vazirmatn
    font-awesome
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    nerd-fonts.fira-code
  ];
  fonts.fontconfig = {
    defaultFonts = {
      serif = [  "Liberation Serif" "Vazirmatn" ];
      sansSerif = [ "Ubuntu" "Vazirmatn" ];
      monospace = [ "FiraCode" ];
    };
  };

  environment.systemPackages = with pkgs; [
    kitty
    pciutils
    wget
    tree
    ntfs3g
    unzip
    jq
  ];

  programs = {
    # Required because zsh is the default login shell (generic.nix).
    # Everything else (plugins, prompt, completion, fzf) lives in
    # home/modules/shell.nix; compinit runs there, so skip it here.
    zsh = {
      enable = true;
      enableCompletion = false;
      promptInit = ""; # oh-my-posh (home-manager) owns the prompt
    };
    git.enable = true;
    vim.enable = true;
    neovim.enable = true;
  };

  # Lets home-manager's zsh complete commands from system packages.
  environment.pathsToLink = [ "/share/zsh" ];

}

