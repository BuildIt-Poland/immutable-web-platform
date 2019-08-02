{pkgs, docker}: 
  let
    current = toString ./.;
    # INFO: this cd is so so but otherwise gosu have lots of issues
  in
    pkgs.writeScriptBin "configuration-test-express-app" ''
      cd ${current}
      export GOSS_FILES_STRATEGY=cp
      ${pkgs.dgoss}/bin/dgoss run -e "TARGET=dgoss" ${docker.imageName}:${docker.imageTag}
    ''