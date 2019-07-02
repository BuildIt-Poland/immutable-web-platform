{ config, pkgs, nodes, local-nixpkgs ? null, ... }:

with pkgs.lib;
# ISSUE: when deploying with nixops workers can stuck as they are waiting for secret for cert manager
# SOLUTION: feel free to break the deployment if master was ok - after calling nixos-kubernetes-join-cluster all should be good
# or better -> add if if it is a node then do not start cert manager
let
  masterNames = 
    (filter (hostName: any (role: role == "master")
                           nodes.${hostName}.config.services.kubernetes.roles)
            (attrNames nodes));
  
  masterName = head masterNames;
  masterHost = nodes.${masterName};

  isMaster = any (role: role == "master") config.services.kubernetes.roles;

  domain = "cluster.local";
in

{
  imports = [
  ];

  systemd.services.kube-control-plane-online.preStart =
    let
      cfg = config.services.kubernetes;
    in pkgs.lib.mkForce ''
      until curl -k -Ssf ${cfg.apiserverAddress}/healthz; do
        echo curl -k -Ssf ${cfg.apiserverAddress}/healthz: exit status $?
        sleep 3
      done
    '';

  boot = {
    # https://github.com/NixOS/nixpkgs/issues/59364
    postBootCommands = ''
      rm -fr /var/lib/kubernetes/secrets /tmp/shared/*
    '';
    kernel.sysctl = { 
      "fs.inotify.max_user_instances" = 256; 
      "net.ipv4.conf.all.forwarding" = 1;
      "net.ipv4.conf.default.forwarding" = 1;
    };
  };

  # TODO change to mkIf
  environment.systemPackages = if isMaster then (with local-nixpkgs; [ 
    k8s-cluster-operations.apply-cluster-stack 
    k8s-cluster-operations.apply-functions-to-cluster
    pkgs.kubernetes
  ]) else [];

  services.kubernetes = {
    # addons.dashboard.enable = true;
    easyCerts = true;
    masterAddress = "${masterHost.config.networking.hostName}.${domain}";
    clusterCidr = "10.244.0.0/16"; #flannel requirements?
    # clusterCidr = ".";
    featureGates = ["DebugContainers"];
    flannel.enable = true;
    proxy.enable = true;
    kubelet = {
      # enable = true;
      allowPrivileged = true;
      # networkPlugin = "cni";
      # kubeconfig.server = "${masterHost.config.networking.privateIPv4}";
      # kubeconfig.server = "api.${domain}";
      verbosity = 5;
      extraOpts = ''
        --fail-swap-on=false
        --read-only-port=10255
      '';
      # cni.config = [{
      #   name = "mynet";
      #   type = "bridge";
      #   bridge = "cni0";
      #   addIf = true;
      #   ipMasq = true;
      #   isGateway = true;
      #   ipam = {
      #     type = "host-local";
      #     subnet = "10.1.0.0/16";
      #     gateway = "10.1.0.1";
      #     routes = [{
      #       dst = "0.0.0.0/0";
      #     }];
      #   };
      # }];
    };
    addons = {
      dashboard = {
        enable = true;
        rbac = {
          enable = true;
          clusterAdmin = true;
        };
      };
      dns = {
        enable = true;
        # clusterDomain = "${domain}";
      };
    };
    # READ! https://github.com/kelseyhightower/kubernetes-the-hard-way/issues/248#issuecomment-341544153
    # https://github.com/kelseyhightower/kubernetes-the-hard-way
    apiserver = {
      allowPrivileged = true;
      extraOpts = "--service-account-lookup=true";
      # serviceAccountKeyFile = config.services.kubernetes.pki.certs.serviceAccount.key;
      serviceAccountKeyFile = config.services.kubernetes.pki.certs.apiServer.caCert;

      # serviceClusterIpRange = "10.0.0.0/24";
     # securePort = 6443;
      advertiseAddress = "${masterHost.config.networking.privateIPv4}:6443"; # WTF https://github.com/NixOS/nixpkgs/blob/release-19.03/nixos/modules/services/cluster/kubernetes/default.nix#L286
    };
    # pki.certs = { inherit dev; };
  };

  networking = {
    inherit domain;
    nameservers = ["10.0.0.254"];

    # enableIPv6 = false;

    extraHosts = ''
      ${masterHost.config.networking.privateIPv4}  api.${domain}
      ${masterHost.config.networking.privateIPv4} etcd.${domain}
      ${concatMapStringsSep "\n" (hostName:"${nodes.${hostName}.config.networking.privateIPv4} ${hostName}.${domain}") (attrNames nodes)}
    '';
    # https://github.com/kubernetes/kubeadm/issues/193
    firewall = {
      allowedTCPPorts = if isMaster then [
        10250      # kubelet
        10255      # kubelet read-only port
        2379 2380  # etcd
        443
        6443        # kubernetes apiserver
      ] else [
        10250      # kubelet
        10255      # kubelet read-only port
      ];
      # "vxlan" 
      trustedInterfaces = [ "docker0" "flannel.1" "enp0s3" "enp0s8" "vxlan" ];

      # allow any traffic from all of the nodes in the cluster
      extraCommands = concatMapStrings (node: ''
        iptables -A INPUT -s ${node.config.networking.privateIPv4} -j ACCEPT
        ${if isMaster then "iptables -P FORWARD ACCEPT" else ""}
      '') (attrValues nodes);
    };
  };
}