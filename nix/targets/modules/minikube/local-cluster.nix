{config, pkgs, lib, inputs, ...}:
with lib;
let
  cfg = config;

  push-docker-images-to-docker-deamon = 
    let
      images = pkgs.k8s-operations.docker-images (desc: 
        let
          docker = desc.value;
        in
        ''
          ${log.info "Pushing docker image, for ${desc.name} to docker daemon: ${docker.name}:${docker.tag}"}
          ${pkgs.docker}/bin/docker load -i ${docker.image}
        '');
    in
      pkgs.writeScriptBin "push-docker-images-to-docker-deamon" images;
in
rec {
  imports = [
    ./docker.nix
  ];

  options.local-cluster = {
    enable = mkOption {
      default = true;
    };
  };

  config = mkIf (cfg.local-cluster.enable) (mkMerge [
    { checks = ["Enabling docker module for minikube"]; }

    ({
      kubernetes.imagePullPolicy = "Never";
      storage.provisioner = "k8s.io/minikube-hostpath";
    })

    (mkIf cfg.docker.upload {
      packages = with pkgs; [
        push-docker-images-to-docker-deamon
      ];

      actions.queue = [{ 
        priority = cfg.actions.priority.docker; 
        action = ''
          push-docker-images-to-docker-deamon
        '';
      }];
    })
  ]);
}