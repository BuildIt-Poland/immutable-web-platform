
# kub = config.services.kubernetes;
# devCert = kub.lib.mkCert {
#   name = "gui";
#   CN = "kubernetes-cluster-ca";
#   fields = {
#     O = "system:masters";
#   };
#   privateKeyOwner = "gui";
# };
# kubeConfig = kub.lib.mkKubeConfig "gui" {
#   server = kub.apiserverAddress;
#   certFile = devCert.cert;
#   keyFile = devCert.key;
# };
# https://github.com/NixOS/nixpkgs/pull/45670/files#diff-8c4e3a8a3bb211a53525fb97850e1fcfR115
# https://logs.nix.samueldr.com/nixos-kubernetes/2018-09-06
# services.kubernetes = {
#   # masterAddress = "master.example.com";
#   # addons.dashboard.enable = true;
#   # kubelet.extraOpts = "--fail-swap-on=false";
#   roles = ["master" "node"];
#   easyCerts = true;
#   masterAddress = "localhost";
#   pki.certs = { dev = devCert; };
#   # masterAddress = "localhost";
#   # easyCerts = true;
#   # apiserver = {
#   #   securePort = 443;
#   #   advertiseAddress = config.networking.privateIPv4;
#   # };
#   # masterAddress = "api.kube";
# };

# export KUBECONFIG="${kubeConfig}:$HOME/.kube/config";
# echo ${builtins.toString (builtins.attrNames devCert)}