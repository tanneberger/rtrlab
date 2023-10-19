{ pkgs, config, lib, ... }:{
  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
    '';
    settings = {
      auto-optimise-store = true;
      experimental-features = "nix-command flakes";
    };
  };

  networking.useNetworkd = true;

  console = {
    font = "Lat2-Terminus16";
    keyMap = "uk";
  };

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.supportedLocales = [
    "en_US.UTF-8/UTF-8"
    "en_US/ISO-8859-1"
    "C.UTF-8/UTF-8"
  ];

  environment.systemPackages = with pkgs; [
    git
    htop
    tmux
    screen
    neovim
    wget
    git-crypt
    iftop
    tcpdump
    dig
  ];

  networking.firewall.enable = lib.mkDefault true;

  networking.firewall.allowedTCPPorts = [ 22 ];
  users.users.root = {
    openssh.authorizedKeys.keyFiles = [
      ../../keys/ssh/tassilo
    ];
  };
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };
  programs.mosh.enable = true;

  programs.screen.screenrc = ''
    defscrollback 10000

    startup_message off

    hardstatus on
    hardstatus alwayslastline
    hardstatus string "%w"
  '';
}
