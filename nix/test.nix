{pkgs}:
with pkgs;
let
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

  basic-shell = {
    name = "test";
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
  test-scenario  = pkgs.nixosTest test-scenario;
  basic-shell = pkgs.nixosTest basic-shell;
 }