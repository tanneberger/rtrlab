{ lib, ... }:
with lib; {
  options = {
    rtrlab.domain = mkOption {
      type = types.str;
      default = "rtrlab.tanneberger.me";
      description = "domain the server is running on";
    };
  };
}


