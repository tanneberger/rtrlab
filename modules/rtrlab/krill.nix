{pkgs, config, lib, ...}: {
  virtualisation.docker.enable = true;

  #systemd.services."krill" = {
  #  enable = true;
  #  wantedBy = [ "multi-user.target" ]; 
  #  script = ''
  #    ${pkgs.krill}/bin/krill --config ${./krill.conf}
  #  '';
  #};

  services.nginx = {


    virtualHosts."krill.rtrlab.tanneberger.me" = {
      enableACME = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:3000";
      };
    };
  };
}
