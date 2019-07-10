{env-config}: 
rec {
  port = 8080;
  label = "express-app";
  docker-label = "${env-config.docker.namespace}/${label}";

  cpu = 
    if env-config.is-dev 
      then "100m" 
      else "1000m";

  env = [{
    name = "TARGET";
    value = "Node.js Sample v1";
  }];
}