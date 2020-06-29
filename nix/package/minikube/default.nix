# should be called helper
# FIXME this should live close to nix/target/minikube
{ pkgs }:
let
  rootFolder = toString ../..;
  baseConfig = rootFolder + "/kubernetes";
  resourcesLocation = baseConfig + "/infra/overlays/local";
  configLocation = baseConfig + "/infra/base/helm";

  addHelmRepo = name: repo:
    "${pkgs.kubernetes-helm}/bin/helm repo add ${name} ${repo}";

  installHelmChart = name: chart: config: version:
    ''
      ${pkgs.kubernetes-helm}/bin/helm upgrade \
        --install ${name} ${chart} \
        -f ${configLocation + "/${config}"} \
        --namespace infra \
        --version ${version}
    '';

  copyConfigMap = nsFrom: nsTo: name: ''
    ${pkgs.kubectl}/bin/kubectl get cm -n ${nsFrom} ${name} --export --output yaml | \
       ${pkgs.kubectl}/bin/kubectl apply -n ${nsTo} -f -
  '';

  copySecret = nsFrom: nsTo: name: ''
    ${pkgs.kubectl}/bin/kubectl get secret -n ${nsFrom} ${name} --export --output yaml | \
       ${pkgs.kubectl}/bin/kubectl apply -n ${nsTo} -f -
  '';

  createNs = name: ''
    ${pkgs.kubectl}/bin/kubectl create namespace ${name}
  '';
in
rec {
  inject-proxy = pkgs.writeScriptBin "inject-proxy" ''
    service=$1
    namespace=$2

    echo Injecting proxy to ns: $namespace for svc: $service

    ${pkgs.kubectl}/bin/kubectl get deploy -o yaml -n $namespace $service | \
      ${pkgs.linkerd}/bin/linkerd inject - | \
      ${pkgs.kubectl}/bin/kubectl apply -f -
  '';

  setup-kubernetes =
    let
      file = pkgs.fetchurl {
        url = https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml;
        sha256 = "00npj9mqi03w0g3382x580ifmpz38sjwk7ilrishv3glpjkfp6i4";
      };

      configMaps = [
        (copyConfigMap "infra" "service" "endpoints")
        (copyConfigMap "infra" "service" "logstash-helm-default-values")
        (copyConfigMap "infra" "stream-infra" "endpoints")
        (copySecret "infra" "service" "db-postgresql")
        (copySecret "infra" "stream" "db-postgresql")
        (copySecret "infra" "stream-infra" "db-postgresql")
        # use only this one
        (copySecret "infra" "service" "postgres-config")
      ];

      namespaces = [
        (createNs "infra")
        (createNs "service")
        (createNs "stream")
        (createNs "stream-infra")
      ];
    in
      # helm-x kustomize to helm?
      # bazel run //kubernetes/services:upload_docker_image
      pkgs.writeScriptBin "setup-kubernetes" ''
        ${pkgs.bazel}/bin/bazel run //kubernetes/services:upload_docker_image

        ${builtins.concatStringsSep "\n" namespaces}

        ${installHelmChart "helm-operator" "fluxcd/helm-operator" "helm-operator.yaml" "1.0.2"}

        ${pkgs.helmfile}/bin/helmfile -f ${rootFolder}/helmfile.yaml sync

        ${wait-for-crd}

        ${pkgs.kubectl}/bin/kubectl apply -f ${file}
        ${pkgs.kustomize}/bin/kustomize build ${resourcesLocation} | ${pkgs.kubectl}/bin/kubectl apply -f -
        ${builtins.concatStringsSep "\n" configMaps}
      '';

  enable-request-tracking = pkgs.writeScriptBin "enable-request-tracking" ''
    ${pkgs.linkerd}/bin/linkerd install | kubectl apply -f -
    ${pkgs.linkerd}/bin/linkerd check
  '';

  deploy-services = pkgs.writeScriptBin "deploy-services" ''
    services=$(${pkgs.bazel}/bin/bazel query 'filter("k8s_update", kind("sh_test", //...))')

    for service in $services; do
      ${pkgs.bazel}/bin/bazel run $service
    done
  '';

  deploy-service-partially = pkgs.writeScriptBin "deploy-service-partially" ''
    services=$(${pkgs.bazel}/bin/bazel query 'filter("k8s_update", kind("sh_test", //...))' | grep $1)

    for service in $services; do
      ${pkgs.bazel}/bin/bazel run $service
    done
  '';

  delete-local-cluster = pkgs.writeScriptBin "delete-local-cluster" ''
    ${pkgs.minikube-eisl}/bin/minikube delete
  '';

  helm-delete-releases = pkgs.writeScriptBin "helm-delete-releases" ''
    ${pkgs.kubernetes-helm}/bin/helm ls --all --short | xargs -L1 ${pkgs.kubernetes-helm}/bin/helm delete
  '';

  create-local-cluster = pkgs.writeScriptBin "create-local-cluster" ''
    ${pkgs.minikube-eisl}/bin/minikube start \
      --cpus 6 \
      --memory 16400
  '';

  check-if-already-started = pkgs.writeScriptBin "check-if-minikube-started" ''
    echo $(${pkgs.minikube-eisl}/bin/minikube status --format {{.Kubelet}} \ | wc -c)
  '';

  create-local-cluster-if-not-exists = pkgs.writeScriptBin "create-local-cluster-if-not-exists" ''
    isRunning=$(${check-if-already-started}/bin/check-if-minikube-started)
    if [ $isRunning = "0" ]; then
      echo "Running minikube"
      ${create-local-cluster}/bin/create-local-cluster
    fi
  '';

  setup-env-vars = pkgs.writeScriptBin "setup-env-vars" ''
    isRunning=$(${check-if-already-started})
    if [ $isRunning = "1" ]; then
      eval $(${pkgs.minikube-eisl}/bin/minikube docker-env)
    fi
  '';

  wait-for =
    { service
    , namespace ? ""
    , extraArgs ? ""
    , selector ? ""
    , condition ? "condition=Ready"
    , resource ? "pod"
    , timeout ? 300
    ,
    }:
      pkgs.writeScript "wait-for" ''

        ${pkgs.kubectl}/bin/kubectl wait \
          --for=${condition} ${resource} \
          --timeout=${toString timeout}s \
          ${if namespace != "" then "--namespace '${namespace}'" else ""} \
          ${extraArgs} \
          ${if selector != "" then "--selector '${selector}'" else ""}
    '';

  wait-for-crd = wait-for {
    service = "crd";
    condition = "condition=established";
    resource = "crd";
    extraArgs = "--all";
  };
}

