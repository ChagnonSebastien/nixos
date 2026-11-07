{ ... }:
{
  # Neovim via nixvim: catppuccin, cmp + luasnip, LSPs, telescope.
  programs.nixvim = {
    enable = true;
    nixpkgs.useGlobalPackages = true;

    colorschemes.catppuccin.enable = true;

    plugins = {

      cmp = {
        enable = true;
        autoEnableSources = true;
        settings = {
          experimental = { ghost_text = false; };
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
          nil_ls = {
            enable = true;
            autostart = true;
            settings = {
              autoArchive = true;
            };
          };
          clangd = { enable = true; autostart = true; };
          gopls = { enable = true; autostart = true; };
          ts_ls = { enable = true; autostart = true; };
        };
      };
      lualine.enable = true;
      luasnip.enable = true;
      lsp-lines.enable = true;
      illuminate = {
        enable = true;
        settings = {
          delay = 100;
        };
      };
      telescope = {
        enable = true;
        autoLoad = true;

      };
      web-devicons.enable = true;
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
}
