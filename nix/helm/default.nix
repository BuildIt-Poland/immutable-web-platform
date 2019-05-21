{
  pkgs, 
  stdenv,
  env-config, 
  callPackage,
  runCommand,
  kubenix,
  lib
}:
let
  getCharts = charts:
    builtins.filter 
      (x: !builtins.elem x ["override" "overrideDerivation"]) 
      (builtins.attrNames charts);
in
rec {
  charts = callPackage ./repository.nix {};

  # HELM & KIND issue: https://github.com/helm/helm/issues/3130
  # todo add check if tiller already exists
  create-tiller-role = pkgs.writeScript "create-tiller-role" ''
    ${pkgs.kubectl}/bin/kubectl --namespace kube-system create serviceaccount tiller
    ${pkgs.kubectl}/bin/kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller
  '';

  init = pkgs.writeScriptBin "helm-init" ''
    echo "helm - taking kubeconfig from: ${env-config.kubeconfigPath}"

    ${create-tiller-role}

    ${helm-local}/bin/helm init --upgrade \
        --service-account tiller \
        --history-max 200 \
        --wait
  '';

  _add-repositories = pkgs.writeScript "add-helm-repositories" 
    (lib.concatMapStrings
      (chartName: 
        let 
          descriptor = charts."${chartName}";
        in
        '' 
          ${helm-local}/bin/helm upgrade --install \
            ${chartName} \
            ${descriptor.chart} \
            -f ${descriptor.values} 
        ''
      ) 
      (getCharts charts)
    );

  # KIND: not sure why it is failing because of that --set KUBECONFIG "${env-config.kubeconfigPath}" 
  helm-local = runCommand "wrap-helm" { 
    buildInputs = [ pkgs.makeWrapper pkgs.kubernetes-helm ]; 
  }
    ''
      mkdir -p $out/bin
      makeWrapper ${pkgs.kubernetes-helm}/bin/helm $out/bin/helm \
        --set HELM_HOME "${env-config.helmHome}"
    '';

  add-repositories = stdenv.mkDerivation {
    name = "add-repositories";
    version = "0.0.1";
    src = ./.;
    phases = ["installPhase"];
    buildInputs = [helm-local];
    installPhase = ''
      mkdir -p $out/bin
      cp ${_add-repositories} $out/bin/${_add-repositories.name}
    '';
  };
}
