{pkgs, env-config}:
with pkgs;
let
  docker = "${pkgs.docker}/bin/docker";

  docker-cfg = env-config.docker;
  registry-alias = "${docker-cfg.registry}";            # dev.local - to make knative happy
  exposed-port = docker-cfg.local-registry.exposedPort; # 32001
  cluster-name = env-config.projectName;

  change-config = pkgs.writeScript "change-config" ''
    sed '/\[plugins.cri.registry.mirrors\]/s/.*/&\
        \    [plugins.cri.registry.mirrors."${registry-alias}"\]\
        \      endpoint = \["http:\/\/host.docker.internal:${toString exposed-port}"\]/' $1 > $1.toml
  '';

  get-kind-nodes = pkgs.writeScript "get-kind-nodes" ''
    ${docker} ps --filter 'name=${cluster-name}-*' --format "{{.Names}}"
  '';

  get-node-config = pkgs.writeScript "get-node-config" ''
    node=$1
    ${docker} exec $node cat /etc/containerd/config.toml
  '';

  copy-config = pkgs.writeScript "copy-config-to-node" ''
    config=$1
    node=$2
    ${docker} cp $config.toml $node:/etc/containerd/config.toml
  '';

  restart-node-containerd = pkgs.writeScript "restart-node-containerd" ''
    node=$1
    ${docker} exec $node systemctl restart containerd.service
    ${docker} exec $node systemctl restart kubelet.service
  '';
in
pkgs.writeScriptBin "append-local-docker-registry" ''
  TEMP=$(mktemp -d)

  for node in $(${get-kind-nodes}); do
    config="$(${get-node-config} $node)"
    config_location=$TEMP/$node

    if [[ "$config" != *"${registry-alias}"* ]]; then
      echo "$config" > $config_location

      ${change-config} $config_location
      ${copy-config} $config_location $node
      ${restart-node-containerd} $node
      echo "Adding local docker registry to node: $node"
    else
      echo "Containerd already aware of local registry: $node"
    fi
  done
''
