{ config, lib, pkgs, ... }:
let
  # When using easyCerts=true the IP Address must resolve to the master on creation.
 # So use simply 127.0.0.1 in that case. Otherwise you will have errors like this https://github.com/NixOS/nixpkgs/issues/59364
  kubeMasterIP = "192.168.0.2";
  kubeMasterHostname = "api.kube";
  kubeMasterAPIServerPort = 6443;
in
{
  environment.systemPackages = with pkgs; [
    kubectl
    kubernetes-helm
    runc
    openiscsi
    nvidia-container-toolkit
    libnvidia-container
    cni-plugins
    flannel
  ];

  networking.extraHosts = "${kubeMasterIP} ${kubeMasterHostname}";

  users.groups.k3s = {};

  services.openiscsi = {
    enable = true;
    name = "iqn.2025-04.dev.chagnon:longhorn-client";
  };

  virtualisation.containerd = {
    enable = true;
    settings = {
      plugins = {

        "io.containerd.grpc.v1.cri" = {
          enable_cdi = true;
          cdi_spec_dirs = ["/etc/cdi" "/var/run/cdi"];
          containerd = {
            default_runtime_name = "nvidia";
            runtimes = {
              nvidia = {
                privileged_without_host_devices = false;
                runtime_type = "io.containerd.runc.v2";
                options = {
                  # `out` only ships nvidia-ctk
                  BinaryName = "${pkgs.nvidia-container-toolkit.tools}/bin/nvidia-container-runtime";

                  hooks = {
                    prestart = {
                      path = "/run/current-system/sw/bin/nvidia-ctk";
                      args = [ "nvidia-ctk" "prestart" ];
                    };
                  };
                };
              };
            };
          };
        };
        # /opt/cni/bin holds dangling symlinks; these exist once k3s first starts
        "io.containerd.grpc.v1.cri".cni = {
          bin_dir  = "/var/lib/rancher/k3s/data/current/bin";
          conf_dir = "/var/lib/rancher/k3s/agent/etc/cni/net.d";
        };
      };
    };
  };

  systemd.services.k3s.path = with pkgs; [
    containerd
    runc
    nvidia-container-toolkit
    libnvidia-container
    flannel
  ];

  environment.sessionVariables.KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";

  services.k3s = {
    enable = true;
    role = "server";

    # no clusterInit: etcd cannot be migrated back to sqlite
    extraFlags = [
      "--write-kubeconfig-group=k3s"
      "--write-kubeconfig-mode=0640"
      # Encrypt Secrets at rest in the datastore. Without this k3s stores them
      # base64-encoded but in the clear, so anything that reads
      # /var/lib/rancher/k3s/server/db -- including a backup of it -- reads
      # every credential. See services/k8s/external-secrets.
      "--secrets-encryption"
      "--disable traefik"
      "--node-label=nixos-nvidia-cdi=enabled"
      "--node-label=nvidia.com/gpu.present=true"
      "--container-runtime-endpoint"
      "unix:///run/containerd/containerd.sock"
    ];
  };
}

