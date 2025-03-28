{ config, lib, pkgs, ... }:

{
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  environment.systemPackages = with pkgs; [
    kitty
    pciutils
    wget
    tree
    ntfs3g
  ];

  programs = {
    zsh = {
      enable = true;
      ohMyZsh = {
        enable = true;
        theme = "robbyrussell";
        plugins = [ "git" "fzf" ]; 
      };
      histSize = 5000;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;
    };
    git.enable = true;
    vim.enable = true;
    neovim.enable = true;
    fzf = {
      fuzzyCompletion = true;
      keybindings = true;
    };
  };

}

