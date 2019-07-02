{ config, pkgs, nodes, local-nixpkgs ? null, ... }:

with pkgs.lib;
# ISSUE: when deploying with nixops workers can stuck as they are waiting for secret for cert manager
# SOLUTION: feel free to break the deployment if master was ok - after calling nixos-kubernetes-join-cluster all should be good
# or better -> add if if it is a node then do not start cert manager
let
  cfg = config.services.k8s;

  masterNames = 
    (filter (hostName: any (role: role == "master")
                           nodes.${hostName}.config.services.k8s.roles)
            (attrNames nodes));
  
  masterName = head masterNames;
  masterHost = nodes.${masterName};

  isMaster = any (role: role == "master") config.services.k8s.roles;

  domain = "cluster.local";
in
{
  disabledModules = ["services/cluster/kubernetes"];

  imports = [
    (import ./kubelet.nix {
      inherit config;
      pkgs = local-nixpkgs; 
    })
  ];

  # options = {};
  options.services.k8s = with types; {
    dataDir = mkOption {
      # default = "/var/lib/kubernetes";
      default = "/var/lib/kubelet";
      type = path;
    };
    roles = mkOption {
      default = [];
      type = listOf (enum ["master" "node"]);
    };
  };
  # kubeadmin init
  # TODO untaint kubectl taint nodes --all node-role.kubernetes.io/master-
  config = {

    # https://kubernetes.io/docs/setup/production-environment/container-runtimes/#docker
    # cat > /etc/docker/daemon.json <<EOF
    # {
    #   "exec-opts": ["native.cgroupdriver=systemd"],
    #   "storage-driver": "overlay2",
    #   "storage-opts": [
    #     "overlay2.override_kernel_check=true"
    #   ]
    # }
    # EOF
    virtualisation.docker = {
      enable = true;
      extraOptions = "--exec-opt native.cgroupdriver=systemd"; # cgroupfs -> kube
      storageDriver = "overlay2";
    };

    boot = {
      # https://github.com/NixOS/nixpkgs/issues/59364
      postBootCommands = ''
        rm -fr /var/lib/kubernetes/secrets /tmp/shared/*
      '';
      kernel.sysctl = { 
        "fs.inotify.max_user_instances" = 256; 
        "net.ipv4.conf.all.forwarding" = 1;
        "net.ipv4.conf.default.forwarding" = 1;
        "net.bridge.bridge-nf-call-iptables" = 1;
      };
    };

    # kubeadm -> [ERROR Swap]: running with swap on is not supported. Please disable swap
    # https://github.com/NixOS/nixops/issues/1062
    swapDevices = mkForce [ ];

    # TODO kubeadm init --apiserver-advertise-address 192.168.99.253 (masterhost)

    programs.bash = {
      interactiveShellInit = ''
        echo "Hey hey hey"
        echo ${config.networking.privateIPv4}
        echo ${config.system.path}
      '';
      # enable = true;
      # enableCompletion = true;
    };

    networking = {
      inherit domain;

      extraHosts = ''
        ${masterHost.config.networking.privateIPv4}  master-0
        ${masterHost.config.networking.privateIPv4}  api.${domain}
        ${masterHost.config.networking.privateIPv4} etcd.${domain}
        ${concatMapStringsSep "\n" (hostName:"${nodes.${hostName}.config.networking.privateIPv4} ${hostName}.${domain}") (attrNames nodes)}
      '';

      # https://github.com/kubernetes/kubeadm/issues/193
      firewall = {
        allowedTCPPortRanges = [ 
          # monitoring-gateway
          { from = 31300; to = 31310; }
          # testing
          { from = 30000; to = 32000; }
        ];

        allowedUDPPorts = [
          # weavenet
          6783
          6784
        ];
        allowedTCPPorts = if isMaster then [
          10248

          10250      # kubelet
          10255      # kubelet read-only port
          2379 2380  # etcd
          443
          6443        # kubernetes apiserver
          15014 # istio

          #weavenet -> https://www.weave.works/docs/net/latest/kubernetes/kube-addon/#-installation
          6783
          6784
        ] else [
          10250      # kubelet
          10255      # kubelet read-only port
          15014 # istio

          #weavenet
          6783
          6784
        ];
        # "vxlan" 
        trustedInterfaces = [ "docker0" "flannel.1" "cni0" ];

        # allow any traffic from all of the nodes in the cluster
        extraCommands = concatMapStrings (node: ''
          iptables -A INPUT -s ${node.config.networking.privateIPv4} -j ACCEPT
          ${if isMaster then "iptables -P FORWARD ACCEPT" else ""}
        '') (attrValues nodes);
      };
    };

      systemd.targets.kubernetes = {
        description = "Kubernetes";
        wantedBy = [ "multi-user.target" ];
      };
      # docker info | grep -i cgroup
      # kubelet --cgroup-driver=systemd
      systemd.tmpfiles.rules = [
        "d /opt/cni/bin 0755 root root -"
        "d /run/kubernetes 0755 kubernetes kubernetes -"
        "d /var/lib/kubernetes 0755 kubernetes kubernetes -"
        "d /var/lib/kubelet 0755 kubernetes kubernetes -"
      ];

      users.users = singleton {
        name = "kubernetes";
        uid = config.ids.uids.kubernetes;
        description = "Kubernetes user";
        extraGroups = [ "docker" ];
        group = "kubernetes";
        home = cfg.dataDir;
        createHome = true;
      };
      users.groups.kubernetes.gid = config.ids.gids.kubernetes;
  };
}