{pkgs, docker}: 
  let
    current = toString ./.;
    # INFO: this is so so but otherwise gosu have lots of issues
  in
    pkgs.writeScriptBin "configuration-test-express-app" ''
      eval $(${pkgs.minikube}/bin/minikube docker-env -p $PROJECT_NAME)
      cd ${current}
      export GOSS_FILES_STRATEGY=cp
      ${pkgs.dgoss}/bin/dgoss run -e "TARGET=dgoss" dev.local/express-app:dev-build
    ''
      # cat ${config} > goss.yaml