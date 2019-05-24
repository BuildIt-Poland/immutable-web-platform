{env-config}: 
rec {
  port = 8080;
  label = "express-app";

  cpu = 
    if env-config.is-dev 
      then "100m" 
      else "1000m";

  local-development-tag = "latest";

  imagePolicy = 
    if env-config.is-dev 
      then "Never" 
      else "IfNotPresent";

  # https://github.com/knative/serving/blob/6e58358927c4d111b2f39ae1e7c22a8b8cd459aa/config/config-controller.yaml#L28
  docker-tag-for-knative = "dev.local";

  image-name-for-docker-when-dev = 
    "${docker-tag-for-knative}/${label}";

  image-name-for-knative-service-when-dev = 
    "${docker-tag-for-knative}/${label}:${local-development-tag}"; # required by knative

  env = [{
    name = "TARGET";
    value = "Node.js Sample v1";
  }];
}