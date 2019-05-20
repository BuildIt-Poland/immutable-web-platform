{ config, lib, pkgs, ...}:
with lib;
let
  kub = config.services.kubernetes;
  dev = kub.lib.mkCert {
    name = "root";
    CN = "root";
    fields = {
      O = "system:masters";
    };
    privateKeyOwner = "root";
  };
  kubeConfig = kub.lib.mkKubeConfig "root" {
    server = kub.apiserverAddress;
    certFile = dev.cert;
    keyFile = dev.key;
  };
  # extra configuration - for latter
  # kubelet = {
  #   networkPlugin = "cni";
  #   cni.config = [{
  #     name = "mynet";
  #     type = "bridge";
  #     bridge = "cni0";
  #     addIf = true;
  #     ipMasq = true;
  #     isGateway = true;
  #     ipam = {
  #       type = "host-local";
  #       subnet = "10.1.0.0/16";
  #       gateway = "10.1.0.1";
  #       routes = [{
  #         dst = "0.0.0.0/0";
  #       }];
  #     };
  #   }];
  # };
  # networking = rec {
  #   domain = "my.xzy";
  #   nameservers = ["10.0.0.254"];
  #   hostName = "kube";
  #   primaryIPAddress = "192.168.1.1";
  #   firewall = {
  #     allowedTCPPorts = [
  #       80
  #       22
  #       10250 # kubelet
  #     ];
  #     trustedInterfaces = ["docker0" "cni0"];
  #   };
  # };
in
{
  # options.services.kubernetes = {
  #   port = mkOption { type = types.int; default = 3001; };
  #   virtualhost = mkOption { type = types.str; };
  # };  

  config = {
    environment.variables.KUBECONFIG = "${kubeConfig}";

    # because of controlplane not starting
    # https://github.com/NixOS/nixpkgs/issues/60687
    systemd.services.kube-control-plane-online.preStart =
      let
        cfg = config.services.kubernetes;
      in pkgs.lib.mkForce ''
        until curl -k -Ssf ${cfg.apiserverAddress}/healthz; do
          echo curl -k -Ssf ${cfg.apiserverAddress}/healthz: exit status $?
          sleep 3
        done
      '';

    services.kubernetes = {
      roles = [ "master" "node" ];
      addons.dashboard.enable = true;
      kubelet.extraOpts = "--fail-swap-on=false";
      masterAddress = "localhost";
      pki.certs = { inherit dev; };
    };
  };
}