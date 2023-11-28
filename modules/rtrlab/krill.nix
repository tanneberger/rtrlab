{pkgs, config, lib, ...}: {
  
  systemd.services."krill" = {
    enable = true;
    wantedBy = [ "multi-user.target" ]; 
    script = ''
      ${pkgs.krill}/bin/krill --config ${./krill.conf}
    '';
    enivronment = {
    };
  };
}
