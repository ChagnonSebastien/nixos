{ config, pkgs, lib, ...}: {

  imports = [
    ./hyprland.nix
    ./hyprpaper.nix
    ./waybar.nix
  ];

  home.sessionVariables = {
    SUDO_EDITOR = "nvim";
  };

  home.packages = with pkgs; [
    bat
    unzip
    (btop.override { cudaSupport = true; })
    jq
    brave
    librewolf
    qview
    vesktop
    rofi-wayland
    zoxide
    youtube-music
    mpv
    bitwarden
    bitwarden-cli
    jellyfin-media-player
    tlrc # tldr
    satty # Screenshoot editor
    grim # Screenshot from wayland compositor
    slurp # Screenshot zone selection 
    wl-clipboard # Clipboard CLI
    cliphist # Clipboard history
    (writeShellScriptBin "jellyfin" ''
      export QT_QPA_PLATFORM="xcb"
      exec ${pkgs.jellyfin-media-player}/bin/jellyfinmediaplayer "$@"
    '')
    vscodium
    dust
    wireguard-tools
    caprine
    element-desktop
    libreoffice-qt6-still
    qbittorrent-enhanced
    beekeeper-studio
    (writeShellScriptBin "beekeeper" ''
      export LIBGL_ALWAYS_SOFTWARE=1
      exec ${pkgs.beekeeper-studio}/bin/beekeeper-studio "$@"
    '')
    jetbrains.idea-ultimate
    wineWowPackages.waylandFull
    winetricks
    prismlauncher
    obs-studio
  ];

  home.sessionPath = [ "$HOME/.local/bin" ];

  xdg.mimeApps = {
    enable = true;
    
    defaultApplications = {
      "text/html" = "librewolf.desktop"; # Replace with your browser's desktop file
      "x-scheme-handler/http" = "librewolf.desktop";
      "x-scheme-handler/https" = "librewolf.desktop";
      "x-scheme-handler/about" = "librewolf.desktop";
      "x-scheme-handler/unknown" = "librewolf.desktop";
    };
  };

  programs.kitty = {
    enable = true;
    settings = {
      enable_audio_bell = false;
    };
    extraConfig = ''
      include ${pkgs.fetchFromGitHub {
        owner = "catppuccin";
        repo = "kitty";
        rev = "main";
        sha256 = "1sfjwvn6xwc882mzv9nhb8wsw3q4kapypq7gh1dkq3jqcjc717b3";
      }}/themes/mocha.conf
    '';
  };

  programs.git = {
    enable = true;
    userName = "Sebastien Chagnon";
    userEmail = "sebastien.chagnon@proton.me";
    extraConfig = {
      push.default = "current";
    };

  };

  programs.zsh = {
    enable = true;
    shellAliases = {
      ls = "ls --color";
      c = "clear";
      nrt = "sudo nixos-rebuild test";
      nrs = "sudo nixos-rebuild switch";
    };
    envExtra = ''
      ZSH_WEB_SEARCH_ENGINES=(
        nixpkg "https://search.nixos.org/packages?channel=unstable&from=0&size=50&sort=relevance&type=packages&query="
      )
    '';
    initExtra = ''
      precmd() { print "" }
    '';
    antidote = {
      enable = true;
      plugins = [
        "Aloxaf/fzf-tab"
        "zdharma-continuum/fast-syntax-highlighting"
        "zsh-users/zsh-completions"
        "zsh-users/zsh-autosuggestions"
        "chisui/zsh-nix-shell"
        "agkozak/zsh-z"
        "getantidote/use-omz"
        "ohmyzsh/ohmyzsh path:lib"
        "ohmyzsh/ohmyzsh path:plugins/git"
        "ohmyzsh/ohmyzsh path:plugins/sudo"
        "ohmyzsh/ohmyzsh path:plugins/web-search"
        "ohmyzsh/ohmyzsh path:plugins/command-not-found"
      ];
    };
  };

  programs.oh-my-posh = {
    enable = true;
    enableZshIntegration = true;
    useTheme = "tiwahu";
  };

  programs.zoxide = {
    enable = true;
    options = [ "--cmd cd" ];
    enableZshIntegration = true;
  };

  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
  };
  
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  # The state version is required and should stay at the version you
  # originally installed.
  home.stateVersion = "24.05";
}
