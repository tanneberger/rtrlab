{ pkgs, config, lib, ... }:
let
  http-host = "127.0.0.1";
  http-port = 8323;
  rtr-host = "0.0.0.0";
  rtr-port = 3324;

  config-file = pkgs.writeText "routinator.conf" ''

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
    repository-dir = "/var/lib/routinator/rpki-cache/repository"
    rsync-command = "${pkgs.rsync}/bin/rsync"
    rtr-listen = ["${rtr-host}:${toString rtr-port}"]
    http-listen = ["${http-host}:${toString http-port}"]
  '';

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
      ${pkgs.aspa_routinator}/bin/routinator --config ${config-file} --no-rir-tals --tal=nlnetlabs-testbed server     
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

  networking.firewall.allowedTCPPorts = [ rtr-port 22 ];
}
