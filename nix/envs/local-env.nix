{config, shell-modules, inputs, ...}: 
{
  imports = with shell-modules.modules; [
    base
    project-configuration
    kubernetes
    docker
    brigade
  ];

  config = {
    environment.type = "local";

    docker = {
      upload-images = ["functions" "cluster"];
      namespace = "dev.local";
      registry = "";
      tag = inputs.docker.hash || "dev-build";
    };

    brigade = {
      enabled = true;
      secret-key = inputs.brigade.secret;
    };

    kubernetes = {
      resources.apply = inputs.kubernetes.update;
      cluster.clean = inputs.kubernetes.clean;
      imagePullPolicy = "Never";
    };
  };
}