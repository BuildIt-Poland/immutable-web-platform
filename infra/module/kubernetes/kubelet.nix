{ config, pkgs, ... }:
with pkgs.lib;
let
  cfg = config.services.k8s;
  packages = [pkgs.cni-plugins];
in
{
  options.services.k8s = with types; {
    kubelet = {
      enable = mkEnableOption "Kubernetes kubelet.";
      allowPrivileged = mkOption {
        default = true;
        type = bool;
      };
    };
  };

  config = {
    boot.kernelModules = ["br_netfilter"];

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
    # https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/kubelet-integration/#the-kubelet-drop-in-file-for-systemd
    systemd.services.kubelet = {
      enable = false;
      description = "Kubernetes Kubelet Service";
      requires = ["docker.service"];
      wantedBy = [ "kubernetes.target" ];
      after = [ "network.target" "docker.service" ];
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
        export PATH="${config.system.path}/bin:$PATH";

        ${pkgs.kubernetes}/bin/kubelet \
          $KUBELET_KUBECONFIG_ARGS \
          $KUBELET_CONFIG_ARGS \
          $KUBELET_KUBEADM_ARGS \
          $KUBELET_EXTRA_ARGS \
          --node-ip=${config.networking.privateIPv4} \
          --allow-privileged=${boolToString cfg.kubelet.allowPrivileged}
      '';
      serviceConfig = {
        CPUAccounting = true;
        MemoryAccounting = true;
        Restart = "on-failure";
        RestartSec = "1000ms";
        WorkingDirectory = cfg.dataDir;      
        EnvironmentFile = "/var/lib/kubelet/kubeadm-flags.env";
      };
    };
  };
}