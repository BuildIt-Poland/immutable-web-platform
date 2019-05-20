{
  pkgs, 
  env-config, 
  callPackage
}:
{
  repository = callPackage ./repository.nix {};

  init = pkgs.writeScriptBin "helm-init" ''
    echo "helm - taking kubeconfig from: ${env-config.kubeconfigPath}"

    ${pkgs.kubernetes-helm}/bin/helm init \
      --history-max 200 \
      --kubeconfig ${env-config.kubeconfigPath} \
      --home $(pwd)/.helm \
      --wait
  '';

  add-repositories = pkgs.writeScriptBin "helm-repository-add" ''
  '';

}
