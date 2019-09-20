{pkgs, lib, ...}: {
  imports = [ ];
  # environment.etc.source.source = (builtins.toPath pkgs.project-config.project.rootFolder);
  options.warm-up = {
    preload = lib.mkOption {
      value = false;
    };
  };
} 