{ pkgs, lib, options, osConfig, ...}: {

  home.packages = with pkgs; [
    bat
    # GPU stats only on hosts running the NVIDIA driver (not WSL)
    (btop.override { cudaSupport = builtins.elem "nvidia" osConfig.services.xserver.videoDrivers; })
    tlrc # tldr
    dust

    inetutils
    openssl

    superfile
    (writeShellScriptBin "spf" ''
      exec ${pkgs.superfile}/bin/superfile "$@"
    '')

    claude-code
    python3
  ];

  home = {
    sessionPath = [
      "$HOME/.local/bin"
      "$HOME/go/bin"
    ];
    sessionVariables = {
      SUDO_EDITOR = "nvim";
      SHELL = "${pkgs.zsh}/bin/zsh";
      PYTHONWARNINGS = "ignore::FutureWarning";
      DOTNET_SYSTEM_GLOBALIZATION_INVARIANT = "1";
    };
  };

  services.home-manager.autoExpire = {
    enable = true;
    frequency = "weekly";
    timestamp = "-14 days";
    store = {
      cleanup = true;
      options = "--delete-older-than 14d";
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
    initContent = ''
      precmd() { print "" }
      logout() { loginctl terminate-user "$USER" }
    '';
    antidote = {
      enable = true;
      plugins = [
        "Aloxaf/fzf-tab"
        "zdharma-continuum/fast-syntax-highlighting"
        "zsh-users/zsh-completions"
        "zsh-users/zsh-autosuggestions"
        "chisui/zsh-nix-shell"
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
    options = [ "--cmd j" ];
    enableZshIntegration = true;
  };

  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      enter_accept = true;
    };
  };
  
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  } // lib.optionalAttrs (options.programs.fzf ? historyWidget) {
    # atuin owns Ctrl-R. Option only exists in unstable home-manager;
    # on stable, atuin already wins and there is no warning.
    historyWidget.command = "";
  };
}
