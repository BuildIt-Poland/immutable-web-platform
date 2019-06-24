{ config, lib, pkgs, ...}:
with lib;
let
  kub = config.services.kubernetes;
  # dev = kub.lib.mkCert {
  #   name = "root";
  #   CN = "root";
  #   fields = {
  #     O = "system:masters";
  #   };
  #   privateKeyOwner = "root";
  # };
  # kubeConfig = kub.lib.mkKubeConfig "root" {
  #   server = kub.apiserverAddress;
  #   certFile = dev.cert;
  #   keyFile = dev.key;
  # };
in
{
  # imports = [ kubernetesBaseConfig ];
  # options.services.kubernetes = {
  #   port = mkOption { type = types.int; default = 3001; };
  #   virtualhost = mkOption { type = types.str; };
  # };  

  config = 
  let
    domain = "my.xyz";
  in
  {
    environment.variables.KUBECONFIG = "/etc/kubernetes/cluster-admin.kubeconfig";#"${kubeConfig}";
    # environment.variables.KUBECONFIG = "${kubeConfig}";

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

    # INFO this is only for master
    networking.extraHosts = ''
      ${config.networking.privateIPv4} api.${domain}
      ${config.networking.privateIPv4} etcd.${domain}
      ${config.networking.privateIPv4} ${config.networking.hostName}.${domain}
    '';

    networking.firewall = {
      allowedTCPPorts = [
        10250 # kubelet
        443
      ];
      trustedInterfaces = ["docker0"];
      extraCommands = ''
        iptables -A INPUT -s ${config.networking.privateIPv4} -j ACCEPT
      '';
    };
    
    #https://github.com/NixOS/nixpkgs/blob/master/nixos/tests/kubernetes/base.nix
    boot = {
      # https://github.com/NixOS/nixpkgs/issues/59364
        # rm -rf /var/lib/cfssl /var/lib/kubernetes
      postBootCommands = ''
        rm -fr /var/lib/kubernetes/secrets /tmp/shared/*
      '';
      kernel.sysctl = { "fs.inotify.max_user_instances" = 256; };
    };
    # services.flannel.enable = false;
    # services.flannel.iface = "eth1";
    services.kubernetes = {
      roles = [ "master" "node" ];
      # addons.dashboard.enable = true;
      # masterAddress = "localhost";#config.networking.privateIPv4;
      easyCerts = true;
      masterAddress = "${config.networking.hostName}.${domain}";
      # masterAddress = "localhost";
      kubelet = {
        networkPlugin = "cni";
        extraOpts = "--fail-swap-on=false";
      };
      apiserver = {
        securePort = 443;
        advertiseAddress = config.networking.privateIPv4;
      };
      # pki.certs = { inherit dev; };
    };
  };
}