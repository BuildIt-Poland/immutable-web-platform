{pkgs, ...}: {
  imports = [ ];
  # environment.etc.source.source = (builtins.toPath pkgs.project-config.project.rootFolder);
  # FIXME this is too big use gitignore
  environment.etc.source.source = ../../..;
} 