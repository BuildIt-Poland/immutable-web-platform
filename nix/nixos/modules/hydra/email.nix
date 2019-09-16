{pkgs, ...}: 
let
  project = pkgs.project-config.project;
in 
{
  services.postfix = {
    enable = true;
    setSendmail = true;
  };
}