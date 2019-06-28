{ config, pkgs, nodes, ... }:

with pkgs.lib;

let
  masterNames = 
    (filter (hostName: any (role: role == "master")
                           nodes.${hostName}.config.services.kubernetes.roles)
            (attrNames nodes));
  
  masterName = head masterNames;
  masterHost = nodes.${masterName};

  isMaster = any (role: role == "master") config.services.kubernetes.roles;

  domain = "kubernetes.local";
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
    kernel.sysctl = { "fs.inotify.max_user_instances" = 256; };
  };

  services.kubernetes = {
    # addons.dashboard.enable = true;
    easyCerts = true;
    masterAddress = "${masterHost.config.networking.hostName}.${domain}";

    kubelet = {
      # enable = true;
      allowPrivileged = true;
      networkPlugin = "cni";
      extraOpts = "--fail-swap-on=false";
    };

    apiserver = {
      allowPrivileged = true;
      securePort = 443;
      advertiseAddress = masterHost.config.networking.privateIPv4; #config.networking.privateIPv4;
    };
    # pki.certs = { inherit dev; };
  };

  networking = {
    inherit domain;

    enableIPv6 = false;

    extraHosts = ''
      ${masterHost.config.networking.privateIPv4}  api.${domain}
      ${masterHost.config.networking.privateIPv4} etcd.${domain}
      ${concatMapStringsSep "\n" (hostName:"${nodes.${hostName}.config.networking.privateIPv4} ${hostName}.${domain}") (attrNames nodes)}
    '';

    firewall = {
      allowedTCPPorts = if isMaster then [
        10250      # kubelet
        10255      # kubelet read-only port
        2379 2380  # etcd
        443        # kubernetes apiserver
      ] else [
        10250      # kubelet
        10255      # kubelet read-only port
      ];

      trustedInterfaces = [ "docker0" "flannel.1" "zt0" ];

      # allow any traffic from all of the nodes in the cluster
      extraCommands = concatMapStrings (node: ''
        iptables -A INPUT -s ${node.config.networking.privateIPv4} -j ACCEPT
      '') (attrValues nodes);
    };
  };
}