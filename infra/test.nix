let
  nixpkgs = <nixpkgs>;
  pkgs = import ../nix {
    inputs = {
      environment = "ec2";
    };
  };

  make-test-docker = import "${nixpkgs}/nixos/lib/testing.nix" {
    inherit pkgs;
    system = builtins.currentSystem;
  };

  run-docker-test = x: 
    let
      val = (make-test-docker.runTests x).overrideAttrs (_: {
        requiredSystemFeatures = ["nixos-test"];
      });
    in
      val;

  make-test-nixos = import "${nixpkgs}/nixos/tests/make-test.nix";

  nginx = pkgs.dockerTools.pullImage {
    imageName = "nginxdemos/hello";
    imageDigest = "sha256:f5a0b2a5fe9af497c4a7c186ef6412bb91ff19d39d6ac24a4997eaed2b0bb334";
    sha256 = "0kxh9xbq70b20lmw16qiwnci21266gnyh9i4qxmq5h6kwkzf3cdd";
  };
  express-app = pkgs.lib.head pkgs.application.functions.express-app.images;

  test-scenario = local: {
    name = "test";
    nodes = { 
      # registry = { ... }: {
      #   services.dockerRegistry.enable = true;
      #   virtualisation.docker.enable = true;
      #   services.dockerRegistry.enableDelete = true;
      #   services.dockerRegistry.port = 8080;
      #   services.dockerRegistry.listenAddress = "0.0.0.0";
      #   services.dockerRegistry.enableGarbageCollect = true;
      #   networking.firewall.allowedTCPPorts = [ 8080 ];
      #   virtualisation.docker.extraOptions = "--insecure-registry localhost:8080";
      # };

      machine1 = { pkgs, ... }: { 
        imports = [
          # <nixpkgs/nixos/modules/profiles/minimal.nix>
          # <nixpkgs/nixos/modules/profiles/headless.nix>
        ];

        # virtualisation.dockerPreloader.images = if !local then [nginx express-app] else [];
        # virtualisation.dockerPreloader.images = [nginx];

        environment.systemPackages = []; 
        virtualisation.rkt.enable = true;

      systemd.services."docker-nginx" = 
      let
        serviceName = "test";
      in
      {
        path = [pkgs.rkt];
        description = "Hello rkt";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          ExecStart = ''
            ${pkgs.rkt}/bin/rkt run --insecure-options=image \
              --port=80-tcp:8181 \
              docker-image://${nginx} \
              --name ${serviceName}
          '';
          ExecStop = ''
            ${pkgs.rkt}/bin/rkt stop --force --name ${serviceName}
          '';
          KillMode = "mixed";
          Restart = "always";
        };
      };
        # virtualisation.docker.extraOptions = "--insecure-registry registry:8080";

        # this is extremely slow and require kvm 
        # TODO check if will work on hypervisor->docker

        # or with docker-registry
        # docker-containers.express-app = {
        #   image = "${express-app.imageName}";
        #   ports = ["8282:8080"];
        # };

        # docker-containers.nginx = {
        #   image = "${nginx.imageName}";
        #   ports = ["8181:80"];
        # };
      }; 
      # machine2 = { ... }: { 
      #   imports = [
      #     <nixpkgs/nixos/modules/profiles/minimal.nix>
      #     <nixpkgs/nixos/modules/profiles/headless.nix>
      #   ];

      #   environment.systemPackages = []; 
      # }; 
    };
      # $machine2->waitForUnit("default.target");
      # $machine2->succeed("echo 'test'");

    # $client1->succeed("docker push registry:8080/scratch");

    # $machine1->waitForUnit("docker.service");
      # $machine1->execute("docker load --input='${nginx}'");
      # $machine1->execute("docker load --input='${express-app}'");
      # $registry->execute("docker load --input ${nginx}");
      # $registry->execute("docker load --input ${express-app}");
      # $registry->waitForUnit("docker-registry.service");
      # $registry->waitForOpenPort("8080");

    testScript = ''
      startAll


      $machine1->waitForUnit("sockets.target");

      $machine1->waitForUnit("default.target");
      $machine1->waitForUnit("docker-nginx.service");
      $machine1->waitForOpenPort(8181);
      $machine1->waitUntilSucceeds("curl http://localhost:8181 | grep Hello");
      $machine1->waitUntilSucceeds("curl http://localhost:8181 | grep World");

    '';
      # $machine1->waitForUnit("docker-express-app.service");
      # $machine1->waitForOpenPort(8080);
      # $machine1->waitUntilSucceeds("curl http://localhost:8282 | grep Hello");
    };
in {
  nixos = make-test-nixos (test-scenario false);
  docker = run-docker-test (make-test-docker.makeTest (test-scenario true)).driver;
}