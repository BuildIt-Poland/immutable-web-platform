# [plugins.cri.registry.mirrors."dev.local"]
#  endpoint = ["http://host.docker.internal:32001"]

# test.insecure-registry.io
# apt-get update
# apt-get install vim
# vim /etc/containerd/config.toml
# systemctl restart containerd.service
# systemctl restart kubelet.service - unnecessary?

# preload is not necessary!!!
# crictl pull dev.local/dev/express-app:dev-build

# docker exec future-is-comming-control-plane systemctl restart kubelet.service

# automation
# TOML https://github.com/NixOS/nix/issues/2967

# check https://github.com/windmilleng/kind-local/blob/master/kind-registry.sh#L21

# builtins.fromTOML (builtins.readFile ./config.toml)
# c.plugins.cri.registry.mirrors // { "dev.local" = { endpoint = ["http://host.docker.internal:32001"];};}
# lib.mergeAttrs c ({plugins.cri.registry.mirrors = ({ "dev.local" = { endpoint = ["http://host.docker.internal:32001"];};} // c.plugins.cri.registry.mirrors);})
# json to toml somehow
# docker cp config.toml ${node_name}:/etc/containerd/config.toml
# docker exec ${node_name} systemctl restart containerd.service
# docker exec ${node_name} systemctl restart kubelet.service
# docker exec future-is-comming-control-plane containerd config default > config.toml
# docker ps --filter ancestor=kindest/node:v1.15.0 --format "{{.Names}}"
{pkgs}:
with pkgs;
let
  # inject = file: 
  #   let
  #     config = builtins.fromTOML (builtins.readFile file);
  #     extra-mirrors = { "dev.local" = { endpoint = ["http://host.docker.internal:32001"];};};
  #     merged-config = lib.mergeAttrs config {
  #       plugins.cri.registry.mirrors = 
  #         extra-mirrors // config.plugins.cri.registry.mirrors;
  #     };
  #   in
  #   stdenv.mkDerivation {
  #     name = "inject-docker-registry";
  #     nativeBuildInputs = [pkgs.docker pkgs.remarshall];
  #     phases = ["installPhase" "patchPhase"];
  #     installScript = ''
  #       ${toString merged-config} > $out
  #     '';
  #   };

  change-config = pkgs.writeScript "change-config" ''
    sed '/\[plugins.cri.registry.mirrors\]/s/.*/&\
            \[plugins.cri.registry.mirrors."dev.local"\]\
            \  endpoint = \["http:\/\/host.docker.internal:32001"\]/' $1 > $1.toml
  '';
  docker = "${pkgs.docker}/bin/docker";
  tmp = "";
in
pkgs.writeScriptBin "append-local-docker-registry" ''
  for node in $(${docker} ps --filter ancestor=kindest/node:v1.15.0 --format "{{.Names}}"); do
    config="$(${docker} exec $node cat /etc/containerd/config.toml)"

    if [[ "$config" != *"dev.local"* ]]; then
      echo "$config" > $node
      ${change-config} $node
      ${docker} cp $node.toml $node:/etc/containerd/config.toml
      ${docker} exec $node systemctl restart containerd.service
    else
      echo "Containerd already aware of private registry: $node"
    fi
  done
''
