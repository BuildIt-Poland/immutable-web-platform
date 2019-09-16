{pkgs, ...}: 
let
  project = pkgs.project-config.project;
in 
{
  nix.gc = {
    automatic = true;
    dates = "05:15";
    options = ''--max-freed "$((32 * 1024**3 - 1024 * $(df -P -k /nix/store | tail -n 1 | ${pkgs.gawk}/bin/awk '{ print $4 }')))"'';
  };
}