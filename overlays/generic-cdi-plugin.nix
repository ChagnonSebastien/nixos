{
  buildGoModule,
  fetchFromGitHub,
  dockerTools,
}: let
  pname = "generic-cdi-plugin";
  gomod = buildGoModule {
    inherit pname;
    version = "2024-07-02";
    src = fetchFromGitHub {
      owner = "OlfillasOdikno";
      repo = pname;
      rev = "9eab512f1e913a4b2632c6e1156f80d9214a8415";
      hash = "sha256-zEIRT2j4juDy0uHa/Jje2Zf3pk9TvQ0ski7LyTta4gs=";
    };
    vendorHash = "sha256-OYWkJacsFfc4BWm/wIpEJ/nWtfpPD66pa/ZelNV7KP0=";
  };
in
  dockerTools.buildImage {
    name = "registry.svc.eureka.lan/${pname}";
    tag = gomod.version;
    config = {
      Entrypoint = ["${gomod}/bin/${pname}"];
      Volumes."/data" = {};
    };
  }

