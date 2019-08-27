{ 
  config, 
  lib, 
  kubenix, 
  project-config, 
  ... 
}:
{
  imports = with kubenix.modules; [ 
    docker
  ];

  config = {
    docker.registry.url = project-config.docker.registry; 
  };
}
