{ lib, ... }:
{
  # Git identity and defaults. Work hosts override user.email.
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Sebastien Chagnon";
        # Personal address by default; work hosts override it.
        email = lib.mkDefault "sebastien.chagnon@proton.me";
      };
      core.autocrlf = "input";
      push.default = "current";
      push.autoSetupRemote = true;
      pull.rebase = true;
      alias.lg1 = "!git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)' $(git for-each-ref --format='%(refname)' refs/heads refs/remotes refs/tags | grep -E 'refs/(heads/(master|[^/]+)|remotes/.*/(master|[^/]+)|tags/(v[0-9]{4}\\.[0-9]+)$)')";
      alias.lg2 = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(auto)%d%C(reset)%n''          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)'";
      alias.lg = "lg1";
    };
  };
}
