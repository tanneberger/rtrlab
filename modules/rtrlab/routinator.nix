{ pkgs, config, lib, ... }:
let
  http-host = "127.0.0.1";
  http-port = 8323;

  rtr-host = "0.0.0.0";
  rtr-port = 3324;

  rtr-port-aspa = 3325; 

  config-file = (name: pkgs.writeText "routinator.conf" ''

    allow-dubious-hosts = false
    dirty = false
    disable-rrdp = false
    disable-rsync = false
    enable-aspa = true
    enable-bgpsec = false
    exceptions = []
    expire = 7200
    history-size = 10
    log = "default"
    log-level = "WARN"
    max-ca-depth = 32
    max-object-size = 20000000
    refresh = 600
    retry = 600
    rrdp-fallback-time = 3600
    rrdp-max-delta-count = 100
    rrdp-proxies = []
    rrdp-root-certs = []
    rrdp-timeout = 300
    rrdp-fallback = "stale"
    rrdp-tcp-keepalive = 60
    rsync-timeout = 300
    rtr-client-metrics = false
    rtr-tcp-keepalive = 60
    rtr-tls-listen = []
    stale = "reject"
    strict = false
    syslog-facility = "daemon"
    systemd-listen = false
    unknown-objects = "warn"
    unsafe-vrps = "accept"
    validation-threads = 10
    repository-dir = "/var/lib/${name}/rpki-cache/repository"
    rsync-command = "${pkgs.rsync}/bin/rsync"
  '');

in
{

  nixpkgs.overlays = [
    (final: prev: {
      aspa_routinator = prev.routinator.overrideAttrs (old: {
        buildFeatures = [ "socks" "aspa" ];
	buildNoDefaultFeatures = false;
      });
    })
  ];

  environment.systemPackages = with pkgs; [ routinator ];

  systemd.services."routinator" = {
    enable = true;
    wantedBy = [ "multi-user.target" ];

    script = ''
      ${pkgs.aspa_routinator}/bin/routinator --config ${(config-file "routinator")} --no-rir-tals --extra-tals-dir="/var/lib/routinator/tals" server --http ${http-host}:${toString http-port} --rtr ${rtr-host}:${toString rtr-port}
    '';
  };


  systemd.services."routinator-stable" = {
    enable = true;
    wantedBy = [ "multi-user.target" ];

    script = ''
      ${pkgs.aspa_routinator}/bin/routinator --config ${(config-file "routinator-stable")} server --rtr ${rtr-host}:${toString rtr-port-aspa}
    '';
  };
  services = {
    nginx = {
      enable = true;
      recommendedProxySettings = true;
      virtualHosts = {
        "${config.rtrlab.domain}" = {
          forceSSL = true;
          enableACME = true;
          locations = {
            "/routinator" = {
              proxyPass = "http://${http-host}:${toString http-port}/";
            };
          };
        };
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ rtr-port rtr-port-aspa 22 ];
}
