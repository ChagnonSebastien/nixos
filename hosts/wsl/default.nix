{ ... }:
{
  imports = [
    ../../modules/devtools.nix
  ];

  wsl.enable = true;
  wsl.defaultUser = "seb";

  virtualisation.docker = {
    enable = true;
    listenOptions = [ "/var/run/docker.sock" "127.0.0.1:2375" ];
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  users.users.seb.extraGroups = [ "docker" ];

  # ssh docker context from Windows: NAT wslrelay drops hijacked
  # docker-api streams (run/exec output) but relays ssh fine
  services.openssh = {
    enable = true;
    ports = [ 2222 ];
    listenAddresses = [ { addr = "127.0.0.1"; port = 2222; } ];
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };
  users.users.seb.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDjkq+wJLgt7T5p9sYYeDzLeaVnex6hMDw7kPE0s8bz18gfpU1LUSVbNTswXWMEI91KP9HZ+TWlhnCQ87ZvtnOwK5kbxPJ+EY+BN7LM7dBf8o3StnGmaIbM81MTCSG1a6t5/OeBAaq+VFzPV6RNi6+2Un7pc9Y1fnimZnJR/LQI/9HUQIH3L3QbGLa+yGMXUcmQAed5aD7Vmg80WQa/Mq3m+C3Nf0teTwVONTBC46tVo6cwOTjfIQE2RRcTVIxFABWLDMPJibvYL9761uEaMUdFZGj6/DU1SkrdjLo/KsK+DOqXdgx4U696quEfNnuGWKR82568APichZMQM1ytyWM9mQw+MWw4YJEMs+txSuRuWeNwqkmYH1yCyn/rb+GlalPxPPaOqKDyYaGZSFJU9UjuCBlxDBN1LMTNu3jrnIqPvfA4OhU/RoyWCtyH1JFNUW6lXGXwJbOhOwRTzD994TlQ0TnRKVkVe5CtQPc5txmEM7oirYZlplbUIdNqL6YJz+s= seb@QohashSebastien"
  ];

  system.stateVersion = "24.11";
}
