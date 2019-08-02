{project-config}: 
rec {
  port = 8080;
  label = "express-app";
  docker-label = "${project-config.docker.namespace}/${label}";
  domain = "dev.cluster";
  cpu = 
    if project-config.environment.isLocal
      then "100m" 
      else "1000m";

  env = [{
    name = "TARGET";
    value = "Node.js Sample v1";
  }];
}