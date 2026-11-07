{ pkgs, ... }:
{
  # Cloud / k8s / Go tooling shared by the work machines (Work, WSL).
  home.packages = with pkgs; [
    awscli2
    kubectl
    kubernetes-helm
    k9s
    terraform
    azure-cli
    openssl
    go
    gcc
    postgresql
  ];
}
