{ 
  config, 
  lib, 
  kubenix, 
  env-config, 
  ... 
}:
let
  namespace = env-config.kubernetes.namespace;
in
{
  imports = with kubenix.modules; [ 
    docker
  ];

  config = {
    docker.registry.url = env-config.docker.registry; 
  };
}
