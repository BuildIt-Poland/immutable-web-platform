{pkgs}:
with pkgs;
let  
  make-test-nixos = import <nixpkgs/nixos/tests/make-test.nix>;

  test-scenario = {
    name = "test-scenario";
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

  # TODO add senario to running any variant of shell
  basic-shell = {
    name = "basic-shell";
    nodes = { 
      machine1 = { pkgs, ... }: { 
        imports = [
          <nixpkgs/nixos/modules/profiles/minimal.nix>
          <nixpkgs/nixos/modules/profiles/headless.nix>
        ];

        environment.systemPackages = [pkgs.kail]; 
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
    # calling-pkgs = pkgs.nixosTest test-scenario;
    calling-pkgs = make-test-nixos test-scenario;
  };
  # shell = {
  #   able-to-run = pkgs.nixosTest basic-shell;
  # };
 }