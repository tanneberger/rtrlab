{pkgs, config, lib, ... }: 
let
  http-host = "127.0.0.1";
  http-port = 3000;

  config-file = pkgs.writeText "krill.conf" ''
    storage_uri = "/var/lib/krill/data/"
    tls_keys_dir = $storage_uri/ssl
    log_level = "warn"
    admin_token = "274oSaJhC5BMmvezU7VVhbVC0DeXgKIMuqUITtYx3xRplMRTJpfQ++CokGEK1BgI4Y8c8TcIc7EYBQDw5/enNLQWR6d+deXAGpe7LZHBZw1r7yX/AIRMO6zsoc60+SWHh3gJt8Lm/wCmyodz6aoZpkR+m7yT+IQ1n+Z9PEEbt9gXr6G2jhI7gXWUag695V8zlQI+XpUmgmDpLcfaQYu+5U0wgEp5IB+Sixk4n1y/9NweQTKZ8SBI9w/kP/ZQ"
    ip = "${http-host}"
    port = ${toString http-port}          
    https_mode = "disable"
    service_uri = "https://rtrlab.tanneberger.me/krill"
    ca_refresh_seconds = 5400
    ca_refresh_jitter_seconds = 300
  '';

in {

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
            "/krill" = {
              proxyPass = "http://${http-host}:${toString http-port}/";
            };
          };
        };
      };
    };
  };
}
