{
  # Rootless docker daemon for seb (rootful docker stays off).
  virtualisation.docker = {
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };
}
