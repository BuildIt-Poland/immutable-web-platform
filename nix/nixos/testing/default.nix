let
  nixpkgs = <nixpkgs>;
  pkgs = import nixpkgs {};
  testing = import "${nixpkgs}/nixos/lib/testing.nix" {
    inherit pkgs;
    system = builtins.currentSystem;
  };
  runTests = x: 
    let
      val = (testing.runTests x).overrideAttrs (_: {
        requiredSystemFeatures = ["nixos-test"];
      });
    in
      val;
  # test = testing.makeTest {
  #   name = "test";
  #   nodes = { 
  #     machine1 = { ... }: { 
  #       environment.systemPackages = []; 
  #       virtualisation.docker.enable = true;

  #       virtualisation.dockerPreloader.images = [ pkgs.dockerTools.examples.nginx ];

  #       docker-containers.nginx = {
  #         image = "nginx-container";
  #         ports = ["8181:80"];
  #       };
  #     }; 
  #     machine2 = { ... }: { 
  #       environment.systemPackages = []; 
  #     }; 
  #   };

  #   testScript = ''
  #     startAll;

  #     $machine1->waitForUnit("default.target");
  #     $machine1->succeed("echo 'test'");

  #     $machine2->waitForUnit("default.target");
  #     $machine2->succeed("echo 'test'");

  #     $machine1->waitForUnit("docker-nginx.service");
  #     $machine1->waitForOpenPort(8181);
  #     $machine1->waitUntilSucceeds("curl http://localhost:8181|grep Hello");
  #   '';
  # };
  driver = test.driver;
in 
  runTests driver