{project-config, lib}: 
rec {
  port = 8080;
  label = "express-app";

  domain = project-config.project.make-sub-domain label;

  cpu = 
    if project-config.kubernetes.target == "minikube"
      then "100m" 
      else "1000m";

  env = [{
    name = "TARGET";
    value = "Node.js Sample v1";
  }];
}