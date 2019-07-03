{ config, pkgs, isMaster, ... }:

with pkgs.lib;
let
  cfg = config.services.k8s;
  domain = "cluster.local";
  packages = [pkgs.cni-plugins];

  cniConfig =
    if cfg.cni.config != [] && cfg.cni.configDir != null then
      throw "Verbatim CNI-config and CNI configDir cannot both be set."
    else if cfg.cni.configDir != null then
      cfg.cni.configDir
    else
      (pkgs.buildEnv {
        name = "kubernetes-cni-config";
        paths = imap (i: entry:
          pkgs.writeTextDir "${toString (10+i)}-${entry.type}.conf" (builtins.toJSON entry)
        ) cfg.cni.config;
      });
in
{
  options.services.k8s = with types; {
    # isMaster = {};
    kubelet = {
      enable = mkEnableOption "Kubernetes kubelet.";
      # cgroup-driver = mkOption {};
    };
    # TODO
    cni = {
      packages = mkOption {
        description = "List of network plugin packages to install.";
        type = listOf package;
        default = [];
      };

      config = mkOption {
        description = "Kubernetes CNI configuration.";
        type = listOf attrs;
        default = [{
            cniVersion = "0.3.0";
            name = "mynet";
            type = "flannel";
            # bridge = "cni0";
            delegate = {
              isDefaultGateway = true;
              bridge = "docker0";
            };
          } {
            cniVersion = "0.3.0";
            type = "loopback";
          }];
        example = literalExample ''
          [{
            "cniVersion": "0.2.0",
            "name": "mynet",
            "type": "bridge",
            "bridge": "cni0",
            "isGateway": true,
            "ipMasq": true,
            "ipam": {
                "type": "host-local",
                "subnet": "10.22.0.0/16",
                "routes": [
                    { "dst": "0.0.0.0/0" }
                ]
            }
          } {
            "cniVersion": "0.2.0",
            "type": "loopback"
          }]
        '';
      };

      configDir = mkOption {
        description = "Path to Kubernetes CNI configuration directory.";
        type = nullOr path;
        default = null;
      };
    };
  };

  # /etc/kubernetes/manifests/

  config = {
    boot.kernelModules = ["br_netfilter"];
    # only for masters
    environment.variables.KUBECONFIG = 
      if isMaster 
        then "/etc/kubernetes/admin.conf"#"${kubeConfig}";
        else "/etc/kubernetes/kubelet.conf";

    # environment.etc."kubernetes/manifests".source = [];

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

    # docker info | grep -i cgroup
    networking = {
      firewall = {
        allowedTCPPorts = [
          10248      # healtz
          10250      # kubelet
          10255      # kubelet read-only port
        ];
      };
    };

  # kubeletPahts = [
  #   /var/lib/kubelet/kubeadm-flags.env
  # ]
    systemd.services.docker.before = [ "kubelet.service" ];
    # mk merge does not work
    systemd.services.kubelet = {
      description = "Kubernetes Kubelet Service";
      # unitConfig = { RequiresMountsFor = "/var/lib/kubelet/"; };
      # restartTriggers = [];
      # wantedBy = [ "multi-user.target" ];
      wantedBy = [ "kubernetes.target" ];
      after = [ "network.target" "docker.service" ];
      # requires = ["docker.service"];
      # https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/kubelet-integration/#the-kubelet-drop-in-file-for-systemd
      environment = {
        KUBELET_KUBECONFIG_ARGS = "--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf";
        KUBELET_CONFIG_ARGS = "--config=/var/lib/kubelet/config.yaml";
      };
      path = [ 
        pkgs.kubernetes
        pkgs.ethtool
        pkgs.socat
        pkgs.iptables
        pkgs.docker
        pkgs.cni-plugins
        pkgs.conntrack-tools
      ];

      preStart = ''
        rm -f /opt/cni/bin/* || true
        ${concatMapStrings (package: ''
          echo "Linking cni package: ${package}"
          ln -fs ${package}/bin/* /opt/cni/bin
        '') packages}

        mkdir -p /etc/kubernetes/manifest
      '';
      script = ''
        echo "starting"
        export PATH="${config.system.path}/bin:$PATH";
        ${pkgs.kubernetes}/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_CONFIG_ARGS $KUBELET_KUBEADM_ARGS $KUBELET_EXTRA_ARGS --allow-privileged=true --node-ip=${config.networking.privateIPv4}
      '';
      # --cni-conf-dir=${cniConfig}
      # --allow-privileged=${boolToString cfg.allowPrivileged} \
      serviceConfig = {
        # PermissionsStartOnly=true;
        CPUAccounting = true;
        MemoryAccounting = true;
        Restart = "on-failure";
        RestartSec = "1000ms";
        WorkingDirectory = cfg.dataDir;      
        EnvironmentFile="/var/lib/kubelet/kubeadm-flags.env";
      };
      # unitConfig.ConditionPathExists = kubeletPaths;
    };
  };# else {};
  # )
  # ];
}