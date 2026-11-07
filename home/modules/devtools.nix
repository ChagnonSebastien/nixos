{ pkgs, ... }:
{
  # Cloud / k8s / Go tooling shared by the work machines (work, wsl).
  home.packages = with pkgs; [
    awscli2
    kubectl
    kubernetes-helm
    k9s
    terraform
    azure-cli
    go
    gcc
    postgresql
  ];
}
