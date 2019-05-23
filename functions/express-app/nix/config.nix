{env-config}: 
rec {
  port = 8000;
  label = "express-app";

  cpu = 
    if env-config.is-dev 
      then "100m" 
      else "1000m";

  imagePolicy = 
    if env-config.is-dev 
      then "Never" 
      else "IfNotPresent";

  env = [{
      name = "TARGET";
      value = "Node.js Sample v1";
    } {
      name = "PORT";
      value = toString port;
    }
  ];
}