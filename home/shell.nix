{ pkgs, ...}: {

  home.sessionVariables = {
    SUDO_EDITOR = "nvim";
  };

  home.packages = with pkgs; [
    zsh
    bat
    unzip
    (btop.override { cudaSupport = true; })
    jq
    zoxide
    tlrc # tldr
    cliphist # Clipboard history
    dust
  ];

  home = {
    sessionPath = [ "$HOME/.local/bin" ];
    sessionVariables = {
      SHELL = "${pkgs.zsh}/bin/zsh";
    };
  };

  programs.nixvim = {
    enable = true;

    colorschemes.catppuccin.enable = true;

    plugins = {

      cmp = {
        enable = true;
        autoEnableSources = true;
        settings = {
          experimental = { ghost_text = true; };
          snippet.expand = ''
            function(args)
              require('luasnip').lsp_expand(args.body)
            end
          '';
          keyword_length = 1;
          sources = [
            { name = "nvim_lsp"; }
            { name = "luasnip"; }
            { name = "path"; }
            { name = "buffer"; }
            { name = "nvim_lua"; }
          ];
          window = {
            completion = {
              winhighlight = "FloatBorder:CmpBorder,Normal:CmpPmenu,CursorLine:CmpSel,Search:PmenuSel";
              scrollbar = false;
              sidePadding = 0;
              border = [ "╭" "─" "╮" "│" "╯" "─" "╰" "│" ];
            };

            settings.documentation = {
              border = [ "╭" "─" "╮" "│" "╯" "─" "╰" "│" ];
              winhighlight = "FloatBorder:CmpBorder,Normal:CmpPmenu,CursorLine:CmpSel,Search:PmenuSel";
            };
          };

          mapping = {
            "<C-n>" = "cmp.mapping.select_next_item()";
            "<C-p>" = "cmp.mapping.select_prev_item()";
            "<C-j>" = "cmp.mapping.select_next_item()";
            "<C-k>" = "cmp.mapping.select_prev_item()";
            "<C-d>" = "cmp.mapping.scroll_docs(-4)";
            "<C-f>" = "cmp.mapping.scroll_docs(4)";
            "<C-Space>" = "cmp.mapping.complete()";
            "<S-Tab>" = "cmp.mapping.close()";
            "<Tab>" =
              # lua 
              ''
                function(fallback)
                  local line = vim.api.nvim_get_current_line()
                  if line:match("^%s*$") then
                    fallback()
                  elseif cmp.visible() then
                    cmp.confirm({ behavior = cmp.ConfirmBehavior.Insert, select = true })
                  else
                    fallback()
                  end
                end
              '';
            "<Down>" =
              # lua
              ''
                function(fallback)
                  if cmp.visible() then
                    cmp.select_next_item()
                  elseif require("luasnip").expand_or_jumpable() then
                    vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<Plug>luasnip-expand-or-jump", true, true, true), "")
                  else
                    fallback()
                  end
                end
              '';
            "<Up>" =
              # lua
              ''
                function(fallback)
                  if cmp.visible() then
                    cmp.select_prev_item()
                  elseif require("luasnip").jumpable(-1) then
                    vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<Plug>luasnip-jump-prev", true, true, true), "")
                  else
                    fallback()
                  end
                end
              '';
          };
        };
      };

      lsp = {
        enable = true;
        servers = {
          clangd = {
            enable = true;
            autostart = true;
            rootDir = ''
              function(fname)
                return require("lspconfig.util").root_pattern("compile_commands.json", ".git")(fname)
              end
            '';
          };
          nil_ls = {
            enable = true;
            autostart = true;
          };
          gopls = {
            enable = true;
            autostart = true;
          };
          ts_ls = {
            enable = true;
            autostart = true;
          };
        };
      };
      lualine.enable = true;
      lsp-lines.enable = true;
      illuminate = {
        enable = true;
        delay = 100;
      };
      telescope = {
        enable = true;
        autoLoad = true;

      };
    };

    opts = {
      # Appearance
      number = true;
      relativenumber = true;
      termguicolors = true;
      colorcolumn = "120";
      signcolumn = "yes";
      cmdheight = 1;
      scrolloff = 10;

      # Tab / Indentation
      shiftwidth = 2;
      tabstop = 2;
      softtabstop = 2;
      expandtab = true;
      smartindent = true;
      wrap = false;

      # Behavior
      hidden = true;
      errorbells = false;
      swapfile = false;
      backup = false;
      backspace = "indent,eol,start";
      splitright = true;
      splitbelow = true;
      autochdir = false;

      list = true;
    };
  };

  programs.git = {
    enable = true;
    userName = "Sebastien Chagnon";
    userEmail = "sebastien.chagnon@qohash.com";
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
}
