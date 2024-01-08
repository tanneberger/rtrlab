{pkgs, config, lib, ... }: 
let
  http-host = "127.0.0.1";
  http-port = 3000;
  token = "274oSaJhC5BMmvezU7VVhbVC0DeXgKIMuqUITtYx3xRplMRTJpfQ++CokGEK1BgI4Y8c8TcIc7EYBQDw5/enNLQWR6d+deXAGpe7LZHBZw1r7yX/AIRMO6zsoc60+SWHh3gJt8Lm/wCmyodz6aoZpkR+m7yT+IQ1n+Z9PEEbt9gXr6G2jhI7gXWUag695V8zlQI+XpUmgmDpLcfaQYu+5U0wgEp5IB+Sixk4n1y/9NweQTKZ8SBI9w/kP/ZQ";


  config-file = pkgs.writeText "krill.conf" ''
    storage_uri = "/var/lib/krill/data/"
    tls_keys_dir = "/var/lib/krill/data/ssl"
    log_level = "warn"
    admin_token = "${token}"
    ip = "${http-host}"
    port = ${toString http-port}
    https_mode = "disable"
    service_uri = "https://rtrlab.tanneberger.me/"
    ca_refresh_seconds = 5400
    ca_refresh_jitter_seconds = 300
    
    [testbed]
    rrdp_base_uri = "https://rtrlab.tanneberger.me/rrdp/"
    rsync_jail = "rsync://rtrlab.tanneberger.me/repo/"
    ta_aia = "rsync://rtrlab.tanneberger.me/ta/ta.cer"
    ta_uri = "https://rtrlab.tanneberger.me/ta/ta.cer"


  '';

in {
  # https://krill.docs.nlnetlabs.nl/en/stable/testbed.html

  environment.systemPackages = with pkgs; [ krill ]; 
  environment.variables  = {
	KRILL_CLI_TOKEN = "${token}";
	KRILL_CLI_SERVER = "https://rtrlab.tanneberger.me/";
	KRILL_CLI_MY_CA = "rtrlab";
  };

  systemd.services."krill" = {
    enable = true;
    wantedBy = [ "multi-user.target" ]; 

    script = ''
      ${pkgs.krill}/bin/krill --config ${config-file}
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
            "/" = {
              proxyPass = "http://${http-host}:${toString http-port}/";
            };
          };
        };
      };
    };
  };
}
