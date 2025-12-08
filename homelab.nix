# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:
let
  # When using easyCerts=true the IP Address must resolve to the master on creation.
 # So use simply 127.0.0.1 in that case. Otherwise you will have errors like this https://github.com/NixOS/nixpkgs/issues/59364
  kubeMasterIP = "192.168.0.2";
  kubeMasterHostname = "api.kube";
  kubeMasterAPIServerPort = 6443;
in
{
  imports = [
    ./modules/nvidia-gpu.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader = {
    efi.canTouchEfiVariables = true;
    timeout = 10;
    grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      useOSProber = true;
      default = 0;
    };
  };
  boot.kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = "80";
  boot.kernelParams = [ "nvidia-drm.fbdev=1"];

  hardware.graphics.enable = true;
  hardware.nvidia-container-toolkit.enable = true;
  services.xserver.videoDrivers = ["nvidia"];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.vulkan_beta;
    open = false;
  };

  environment.systemPackages = with pkgs; [
    nvidia-docker
    cudatoolkit
    runc
    openiscsi
    nvidia-container-toolkit
    libnvidia-container
    cni-plugins
    flannel
    kompose
    kubectl
    kubernetes
  ];

  networking.extraHosts = "${kubeMasterIP} ${kubeMasterHostname}";

  networking.hostName = "homelab";
  networking.firewall.enable = false;
  networking.networkmanager.enable = true;
  networking.interfaces.enp42s0 = {
    useDHCP = false;

    ipv4.addresses = [
      {
        address = "192.168.0.2";  # Replace with your desired static IP
        prefixLength = 24;        # Typically 24 for a 255.255.255.0 netmask
      }
    ];
  };

  networking.defaultGateway = {
    address = "192.168.0.1";
    interface = "enp42s0";
  };

  networking.nameservers = [ "8.8.8.8" "8.8.4.4" ];  # Replace with your preferred DNS servers

   virtualisation.docker = {
    enable = true;

    daemon.settings.features.cdi = true;
    rootless = {
      enable = false;
      setSocketVariable = true;
    };

    #extraOptions = "--default-runtime=nvidia";
  };

  users.groups.k3s = {};
  users.users.seb = {
    isNormalUser = true;
    extraGroups = [ "wheel" "seat" "video" "input" "audio" "networkmanager" "docker" ];
    initialPassword = "change-me";
  };

  users.users.marc = {
    isNormalUser = true;
    initialPassword = "change-me";
  };

  services.openssh.enable = true;
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

  #systemd.services.k3s.serviceConfig = {
  #  ExecStartPre = [
  #    # match any “grpc.v1.cri” header (regardless of single‑ or double‑quotes)
  #    "${pkgs.gnused}/bin/sed -i '/plugins.*grpc\\.v1\\.cri/a enable_cdi    = true\\ncdi_spec_dirs = [ \"/var/run/cdi\" ]' /var/lib/rancher/k3s/agent/etc/containerd/config.toml.tmpl"
  #  ];
  #};

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  system.stateVersion = "24.11"; # Did you read the comment?

}

