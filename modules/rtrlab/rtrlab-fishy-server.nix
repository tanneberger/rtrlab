{ pkgs, config, lib, ... }:
let
  rtr-host = "0.0.0.0";
  rtr-port = 3323;
in
{

  systemd.services = {
    "fishy-rtr-server" = {
      enable = true;
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      script = ''
        ${pkgs.rtrlab}/bin/rtrlab-fishy-server
      '';

      environment = {
        "ADDR" = "${rtr-host}:${toString rtr-port}";
        "TOPOLOGY_PATH" = ../../topology.json;
      };

      serviceConfig = {
        Type = "forking";
        User = "rtrlab-fishy-server";
        Restart = "always";
      };
    };
  };


  users.users."rtrlab-fishy-server" = {
    name = "rtrlab-fishy-server";
    isSystemUser = true;
    uid = 1501;
    group = "rtrlab-fishy-server";
  };
  users.groups."rtrlab-fishy-server" = {
    name = "rtrlab-fishy-server";
    gid = 1502;
  };
  networking.firewall.allowedTCPPorts = [ rtr-port 22 ];
}
