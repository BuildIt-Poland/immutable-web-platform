{ config, pkgs, ... }:

with pkgs.lib;
let
  cfg = config.services.k8s;
  domain = "cluster.local";
in
{
  options.services.k8s = with lib.types; {
    kubelet = {
      enable = mkEnableOption "Kubernetes kubelet.";
      # cgroup-driver = mkOption {};
    };
  };

  config = {
    boot.kernelModules = ["br_netfilter"];

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
        # pkgs.docker
      ];# ++ top.path;

      # preStart = ''
      #   ${concatMapStrings (img: ''
      #     echo "Seeding docker image: ${img}"
      #     docker load <${img}
      #   '') cfg.seedDockerImages}
      # '';
      # docker system info --format '{{.CgroupDriver}}'

      # preStart = ''
      # '';
      # take from /var/lib/kubelet/kubeadm-flags.env
      script = ''
        echo "starting"
        echo "env var: $KUBELET_KUBEADM_ARGS"
        echo "env var: $KUBELET_KUBECONFIG_ARGS"
        echo "env var: $KUBELET_KUBEADM_ARGS"
        echo "env var: $KUBELET_EXTRA_ARGS"
        ${pkgs.kubernetes}/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_CONFIG_ARGS $KUBELET_KUBEADM_ARGS $KUBELET_EXTRA_ARGS
      '';
      # --allow-privileged=${boolToString cfg.allowPrivileged} \
      serviceConfig = {
        # Slice = "kubernetes.slice";
        # PermissionsStartOnly=true;
        # CPUAccounting = true;
        # MemoryAccounting = true;
        Restart = "on-failure";
        RestartSec = "1000ms";
        # User = "kubernetes";
        # Group = "kubernetes";
        # WorkingDirectory = cfg.dataDir;      
        # WorkingDirectory="/var/lib/kubelet";
        # User = "kubernetes";
        # WorkingDirectory="/var/lib/kubelet";
        # EnvironmentFile="-/etc/kubernetes/config";
        # EnvironmentFile="-/etc/kubernetes/kubelet";
        EnvironmentFile="/var/lib/kubelet/kubeadm-flags.env";
        # RuntimeDirectory = cfg.dataDir;      
        # RuntimeDirectoryMode="0775";
      };
      # unitConfig.ConditionPathExists = kubeletPaths;
    };
  };# else {};
  # )
  # ];
}