{pkgs, sources}:
let
  make-test-docker = import "${sources.nixpkgs}/nixos/lib/testing.nix" {
    inherit pkgs;
    system = builtins.currentSystem;
  };

  make-test-nixos = import "${sources.nixpkgs}/nixos/tests/make-test.nix";

  test-scenario = local: {
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
  make-test-nixos test-scenario