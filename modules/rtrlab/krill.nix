{pkgs, config, lib, ...}: {
  virtualisation.docker.enable = true;

  systemd.services."krill" = {
    enable = true;
    wantedBy = [ "multi-user.target" ]; 
    script = ''
      ${pkgs.krill}/bin/krill --config ${./krill.conf}
    '';
  };
}
