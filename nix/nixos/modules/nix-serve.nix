{config, pkgs, ...}: {
  environment.systemPackages = [ 
    pkgs.nix-serve
  ];

  services.nix-serve = {
    enable = true;
    port = 5000;
    secretKeyFile = "/etc/nix/${config.networking.hostName}/secret";
  };

  networking.firewall.allowedTCPPorts = [ 5000 ];
}