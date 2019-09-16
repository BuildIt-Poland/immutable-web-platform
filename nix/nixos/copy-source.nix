{pkgs, ...}: {
  imports = [ ];
  environment.etc.source.source = pkgs.project-config.project.rootFolder;
} 