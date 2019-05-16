{ pkgs, lib, ... }:
# TODO ssh keys - check what is best way to achive that in nixos
# service.volumes = [ 
#   "host_keys": "/concourse-keys"
# ];
# TODO how to make a dependencies within services

# LESSON: if there is an image defined, service.useHostStore = true; - does not work
let 
  cwd = toString ./.;
in
{
  # options.domain = lib.mkOption {
  #   type = lib.types.string;
  #   default = "localhost:8080";
  # };

  config.docker-compose.services = {
    # postgres = {
    #   service.image = "postgres";
    #   service.volumes = [ 
    #     "${cwd}/postgres-data:/var/lib/postgresql/data" 
    #   ];
    #   service.environment = {
    #     POSTGRES_DB = "concourse";
    #     POSTGRES_USER = "concourse_user";
    #     POSTGRES_PASSWORD = "concourse_pass";
    #   };
    # };

    web = {
      # TODO volumes with keys
      service.image = "concourse/concourse";
      # service.depends_on = ["postgres"];
      # service.links = ["postgres"]; # double check that
      service.command = ["web"];
      service.ports = [
        # TODO expose to nginx
        "8080:8080" # host:container
      ];
      service.environment = {
        CONCOURSE_EXTERNAL_URL = "http://localhost:8080";
        CONCOURSE_POSTGRES_HOST = "postgres";
        CONCOURSE_POSTGRES_USER = "concourse_user";
        CONCOURSE_POSTGRES_PASSWORD = "concourse_pass";
        CONCOURSE_POSTGRES_DATABASE = "concourse";
        CONCOURSE_ADD_LOCAL_USER = "test:test";
        CONCOURSE_MAIN_TEAM_LOCAL_USER = "test";
      };
      # service.volumes = [ 
      #   "${cwd}/keys/web:/concourse-keys" 
      # ];
    };

    # worker = {
    #   # TODO stop_signal: SIGUSR2
    #   service.depends_on = ["web"];
    #   service.links = ["web"];
    #   service.image = "concourse/concourse";
    #   service.command = ["worker"];
    #   service.environment = {
    #     CONCOURSE_TSA_HOST = "web";
    #     # CONCOURSE = "2222";
    #   };
    #   service.volumes = [ 
    #     "${cwd}/keys/worker:/concourse-keys" 
    #   ];
    # };
  };
}