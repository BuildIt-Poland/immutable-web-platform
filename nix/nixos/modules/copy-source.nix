{pkgs, ...}: {
  imports = [ ];
  # environment.etc.source.source = (builtins.toPath pkgs.project-config.project.rootFolder);
  environment.etc.source.source = ../../..;
} 