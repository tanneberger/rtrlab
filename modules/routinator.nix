{pkgs, config, lib, ... }: 
let

  config-file = pkgs.writeText "routinator.conf" ''
    repository-dir = "/var/lib/routinator/rpki-cache/repository"
    exceptions = []
    strict = false
    stale = "reject"
    unsafe-vrps = "accept"
    unknown-objects = "warn"
    allow-dubious-hosts = false
    disable-rsync = false
    rsync-command = "${pkgs.rsync}/bin/rsync"
    rsync-timeout = 300
    disable-rrdp = false
    rrdp-fallback = "stale"
    rrdp-fallback-time = 3600
    rrdp-max-delta-count = 100
    rrdp-timeout = 300
    rrdp-tcp-keepalive = 60
    rrdp-root-certs = []
    rrdp-proxies = []
    max-object-size = 20000000
    max-ca-depth = 32
    enable-bgpsec = false
    dirty = false
    validation-threads = 16
    refresh = 600
    retry = 600
    expire = 7200
    history-size = 10
    rtr-listen = []
    rtr-tls-listen = []
    http-listen = []
    http-tls-listen = []
    systemd-listen = false
    rtr-tcp-keepalive = 60
    rtr-client-metrics = false
    log-level = "WARN"
    log = "default"
    syslog-facility = "daemon"
  '';

in {
  
  nixpkgs.overlays = [
    (final: prev: {
      routinator = prev.routinator.overrideAttrs (old: {
        buildFeatures = [ "socks" "aspa" ];
      });
    })
  ];


  systemd.services."routinator" = {
    enable = true;
    wantedBy = [ "multi-user.target" ]; 

    script = ''
      ${pkgs.routinator}/bin/routinator --config ${config-file} --extra-tals-dir="/var/lib/routinator/tals"
    '';
  };
 }
