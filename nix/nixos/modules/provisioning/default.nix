{ config, lib, pkgs,...}:
with lib;
with pkgs;
let
  cfg = config.services.k8s;
in
{
  options.services.k8s.resources = {
    auto-provision = mkOption { 
      type = types.bool; 
      default = true; 
    };
  };

  config = (mkIf cfg.resources.auto-provision {
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
      requires = [ "kubelet.service" ];

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
  })
}