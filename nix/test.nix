{pkgs}:
with pkgs;
let  
  make-test-docker = import <nixpkgs/nixos/lib/testing.nix> {
    inherit pkgs;
    system = builtins.currentSystem;
  };

  run-docker-test = x: 
    let
      val = (make-test-docker.runTests x).overrideAttrs (_: {
        requiredSystemFeatures = [];
      });
    in
      val;

  make-test-nixos = import <nixpkgs/nixos/tests/make-test.nix>;

  test-scenario = {...}: {
    name = "test-scenario";
    nodes = { 
      machine1 = { ... }: { 
        imports = [
          <nixpkgs/nixos/modules/profiles/minimal.nix>
          <nixpkgs/nixos/modules/profiles/headless.nix>
        ];

        environment.systemPackages = [kail kubectl-debug]; 
      }; 
    };
    testScript = ''
      startAll

      $machine1->waitForUnit("default.target");
      $machine1->succeed("kail --help");
      $machine1->succeed("kubectl-debug --help");
    '';
    };

  # TODO add senario to running any variant of shell
  basic-shell = {
    name = "basic-shell";
    nodes = { 
      machine1 = { pkgs, ... }: { 
        imports = [
          <nixpkgs/nixos/modules/profiles/minimal.nix>
          <nixpkgs/nixos/modules/profiles/headless.nix>
        ];

        environment.systemPackages = [pkgs.kail ]; 
        # environment.etc.source.source = /etc/source; 
      }; 
    };
    testScript = ''
      startAll

      $machine1->waitForUnit("default.target");
      $machine1->succeed("ls /etc/source");
      $machine1->succeed("nix-shell --help");
    '';
    };
in 
{ 
  smoke = {
    calling-pkgs = (make-test-nixos (test-scenario) {}).test;
    calling-pkgs-r = (make-test-nixos (test-scenario) {}).report;
    calling-pkgs-d = (make-test-nixos (test-scenario) {}).driver;
    calling-pkgs-2 = run-docker-test (make-test-docker.makeTest (test-scenario {})).driver;
    calling-pkgs-3 = pkgs.nixosTest test-scenario;
  };
  # shell = {
  #   able-to-run = pkgs.nixosTest basic-shell;
  # };
 }