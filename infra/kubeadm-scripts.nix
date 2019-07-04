{pkgs}:
with pkgs;
{
  # TODO check if kubernetes is working
  make-master = {ip, pods-cidr}: [
    (writeScriptBin "master-init" ''
      ${pkgs.kubernetes}/bin/kubeadm init \
        --apiserver-advertise-address ${ip} \
        --pod-network-cidr=${pods-cidr}
    '')

    (writeScriptBin "apply-pod-network" ''
      ${pkgs.kubectl}/bin/kubectl apply -f \
        "https://cloud.weave.works/k8s/net?k8s-version=v1.11.1&env.IPALLOC_RANGE=${pods-cidr}"
    '')

    (writeScriptBin "master-untaint" ''
      ${pkgs.kubectl}/bin/kubectl taint nodes --all node-role.kubernetes.io/master-
    '')

    (writeScriptBin "get-join-command" ''
      ${pkgs.kubernetes}/bin/kubeadm token create --print-join-command
    '')
  ];
}