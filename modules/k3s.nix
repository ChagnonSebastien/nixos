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
    cudatoolkit
    nvidia-docker
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
                  BinaryName = "${pkgs.nvidia-container-toolkit}/bin/nvidia-container-runtime";

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
        "io.containerd.grpc.v1.cri".cni = {
          bin_dir  = "/opt/cni/bin";
          conf_dir = "/etc/cni/net.d";
        };
      };
    };
  };

  systemd.services.k3s.path = with pkgs; [
    containerd
    runc
    nvidia-container-toolkit
    nvidia-docker
    libnvidia-container
    flannel
  ];

  services.k3s = {
    enable = false;
    role = "server";
    clusterInit = true;
    extraFlags = [
      "--write-kubeconfig-group=k3s"
      "--write-kubeconfig-mode=0640"
      "--disable traefik"
      "--node-label=nixos-nvidia-cdi=enabled"
      "--node-label=nvidia.com/gpu.present=true"
      "--node-label=nvidia.com/mps.capable=true"
      "--node-label=nvidia.com/device-plugin.config=gtx1080ti"
      "--container-runtime-endpoint"
      "unix:///run/containerd/containerd.sock"
    ];
  };
}

