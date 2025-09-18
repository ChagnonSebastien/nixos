{ pkgs, ... }:

{
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  fonts.enableDefaultPackages = true;
  fonts.packages = with pkgs; [
    ubuntu_font_family
    liberation_ttf
    vazir-fonts
    font-awesome
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
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

