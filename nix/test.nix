{pkgs}:
with pkgs;
let
  # make-test-docker = import "${sources.nixpkgs}/nixos/lib/testing.nix" {
  #   inherit pkgs;
  #   system = builtins.currentSystem;
  # };

  # run-docker-test = x: 
  #   let
  #     val = (make-test-docker.runTests x).overrideAttrs (_: {
  #       requiredSystemFeatures = ["nixos-test"];
  #     });
  #   in
  #     val;

  make-test-nixos = import "<nixpkgs>/nixos/tests/make-test.nix";

  test-scenario = {
    name = "test";
    nodes = { 
      machine1 = { pkgs, ... }: { 
        imports = [
          <nixpkgs/nixos/modules/profiles/minimal.nix>
          <nixpkgs/nixos/modules/profiles/headless.nix>
        ];

        environment.systemPackages = [pkgs.kail]; 
      }; 
    };
    testScript = ''
      startAll

      $machine1->waitForUnit("default.target");
      $machine1->succeed("kail --help");
    '';
    };
in 
{ 
  test-b = pkgs.nixosTest test-scenario;
  test-a = make-test-nixos test-scenario;
  # test-b = run-docker-test (make-test-docker.makeTest test-scenario).driver;
 }