{ self, ... }:
let
  mac_addr = "da:da:da:da:da:42";
in
{
  microvm = {
    hypervisor = "qemu";
    mem = 2048;
    vcpu = 3;
    interfaces = [
      {
        type = "tap";
        id = "flpk-rtrlab";
        mac = mac_addr;
      }
    ];
    shares = [
      {
        source = "/nix/store";
        mountPoint = "/nix/.ro-store";
        tag = "store";
        proto = "virtiofs";
        socket = "store.socket";
      }
      {
        source = "/var/lib/microvms/rtrlab/etc";
        mountPoint = "/etc";
        tag = "etc";
        proto = "virtiofs";
        socket = "etc.socket";
      }
      {
        source = "/var/lib/microvms/rtrlab/var";
        mountPoint = "/var";
        tag = "var";
        proto = "virtiofs";
        socket = "var.socket";
      }
    ];
  };

  networking.hostName = "rtrlab"; # Define your hostname.

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  rtrlab.net.iface.uplink = {
    name = "eth0";
    useDHCP = false;
    mac = mac_addr;
    matchOn = "mac";
    addr4 = "45.158.40.171/27";
    dns = [ "172.20.73.8" "9.9.9.9" ];
    routes = [
      {
        routeConfig = {
          Gateway = "45.158.40.160";
          Destination = "0.0.0.0/0";
        };
      }
    ];
  };


  #sops.defaultSopsFile = self + /secrets/dresden-zone/secrets.yaml;

  system.stateVersion = "23.05";
}
