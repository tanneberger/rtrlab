{pkgs, config, lib, ...}: {
  
  systemd.services.krill = {
    enable = true;
    script = ''
      ${pkgs.krill}/bin/krill
    '';

    environment = {


    };
  };
}
