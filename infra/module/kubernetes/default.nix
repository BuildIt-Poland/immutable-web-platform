{ config, pkgs, nodes, ... }:

with pkgs.lib;
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

  kube-scripts = pkgs.callPackage ./master-scripts.nix {};
in
{
  disabledModules = ["services/cluster/kubernetes"];

  imports = [
    ./kubelet.nix
  ];

  options.services.k8s = with types; {
    enable = mkEnableOption "Kubernetes";

    dataDir = mkOption {
      default = if isMaster then "/var/lib/kubernetes" else "/var/lib/kubelet";
      type = path;
    };
    roles = mkOption {
      default = [];
      type = listOf (enum ["master" "node"]);
    };
    pods-cidr = mkOption {
      default = "10.32.0.0/12";
      type = string;
    };
    cgroup-driver = mkOption {
      default = "systemd";
      type = string;
    };
  };

  # config = mkMerge [
  #   (mkIf true {
  #   })
  #   (mkIf true {
  config = {
    environment.variables.KUBECONFIG = 
        if isMaster 
          then "/etc/kubernetes/admin.conf"
          else "/etc/kubernetes/kubelet.conf";

      environment.systemPackages = with pkgs; [
        kubectl
        kubernetes
        ethtool
        socat
      ] ++ (kube-scripts.make-master {
        ip = config.networking.privateIPv4; 
        pods-cidr = cfg.pods-cidr; 
      });

      # https://kubernetes.io/docs/setup/production-environment/container-runtimes/#docker
      virtualisation.docker = {
        enable = true;
        # INFO https://github.com/weaveworks/weave/issues/2826
        extraOptions = "--exec-opt native.cgroupdriver=${cfg.cgroup-driver} --iptables=false --ip-masq=false -b none"; # cgroupfs -> kube
        logDriver = mkDefault "json-file";
        storageDriver = "overlay2";
      };

      boot = {
        # https://github.com/NixOS/nixpkgs/issues/59364
        postBootCommands = ''
          rm -fr /var/lib/kubernetes/secrets /tmp/shared/*
        '';

        kernel.sysctl = { 
          "net.bridge.bridge-nf-call-iptables" = 1;
        };
      };

      # kubeadm -> [ERROR Swap]: running with swap on is not supported. Please disable swap
      # https://github.com/NixOS/nixops/issues/1062
      swapDevices = mkForce [ ];


      networking = {
        inherit domain;

        extraHosts = ''
          ${concatMapStringsSep "\n" (hostName:"${nodes.${hostName}.config.networking.privateIPv4} ${hostName}") (attrNames nodes)}
          ${concatMapStringsSep "\n" (hostName:"${nodes.${hostName}.config.networking.privateIPv4} ${hostName}.${domain}") (attrNames nodes)}
        '';
        
        firewall = {
          allowedTCPPortRanges = [ 
            # monitoring-gateway
            { from = 31300; to = 31310; }
          ];

          allowedUDPPorts = [
            # weavenet
            6783
            6784
          ];

          allowedTCPPorts = if isMaster then [
            # kube
            2379 2380  # etcd
            6443       # kubernetes apiserver
            8001       # proxy

            10248
            443

            #weavenet -> https://www.weave.works/docs/net/latest/kubernetes/kube-addon/#-installation
            6783
          ] else [ ];
          
          # ifconfig
          trustedInterfaces = [ "docker0" "enp0s3" "enp0s8" "weave" ];

          # allow any traffic from all of the nodes in the cluster
          extraCommands = ''${concatMapStrings (node: "
            iptables -A INPUT -s ${node.config.networking.privateIPv4} -j ACCEPT") (attrValues nodes)}
          '';
        };
      };

      systemd.targets.kubernetes = {
        description = "Kubernetes";
        wantedBy = [ "multi-user.target" ];
      };

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
    #)
  # ];
}