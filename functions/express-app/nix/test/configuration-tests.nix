{pkgs}: 
  pkgs.writeScriptBin "configuration-test-express-app" ''
    echo "Running tests agains express-app"
  ''