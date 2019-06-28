{ config, lib, pkgs, local-nixpkgs,...}:
with lib;
with local-nixpkgs;
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
  options.services.kubernetes.resources = {
    auto-provision = mkOption { type = types.bool; default = true; };
  };  

  config = 
  let
    domain = config.networking.domain;
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

    # TODO use mkIf cfg.enabled https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/cluster/kubernetes/kubelet.nix#L236
    systemd.services.k8s-resources = 
    let
      run = ''
        apply-cluster-stack
        apply-functions-to-cluster
      '';
    in
    {
      enable  = config.services.kubernetes.resources.auto-provision;
      description = "Kubernetes provisioning";
      wantedBy = [ "multi-user.target" ];
      requires = [ "kube-apiserver.service" "kube-controller-manager.service" ];
      after = [ "certmgr.service" "kube-control-plane-online.target"];

      environment = {
        KUBECONFIG = "/etc/kubernetes/cluster-admin.kubeconfig";
      };
      path = [
        k8s-cluster-operations.apply-cluster-stack 
        k8s-cluster-operations.apply-functions-to-cluster
        kubectl
      ];
      script = run;
      reload = run;
      serviceConfig = {
        Type = "oneshot";
      };
    };

    # INFO this is only for master
    networking.extraHosts = ''
      ${config.networking.privateIPv4} api.${domain}
      ${config.networking.privateIPv4} etcd.${domain}
      ${config.networking.privateIPv4} ${config.networking.hostName}.${domain}
    '';

    networking.firewall = {
      allowedTCPPortRanges = [ 
        # monitoring-gateway
        { from = 31300; to = 31310; }
      ];
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

    # INFO -> when changing domain ...
    # rm -rf /var/lib/cfssl /var/lib/kubernetes
    boot = {
      # https://github.com/NixOS/nixpkgs/issues/59364
      postBootCommands = ''
        rm -fr /var/lib/kubernetes/secrets /tmp/shared/*
      '';
      kernel.sysctl = { "fs.inotify.max_user_instances" = 256; };
    };

    services.kubernetes = {
      roles = [ "master" "node" ];
      # addons.dashboard.enable = true;
      easyCerts = true;
      masterAddress = "${config.networking.hostName}.${domain}";
      # masterAddress = "localhost";
      kubelet = {
        allowPrivileged = true;
        networkPlugin = "cni";
        extraOpts = "--fail-swap-on=false";
      };
      apiserver = {
        allowPrivileged = true;
        securePort = 443;
        advertiseAddress = config.networking.privateIPv4;
      };
      # pki.certs = { inherit dev; };
    };
  };
}