# TODO add more tests please!!!
{pkgs}:
with pkgs;
let  
  test-scenario = {pkgs, ...}: {
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
  basic-shell = {...}:{
    name = "basic-shell";
    nodes = { 
      machine1 = { ... }: { 
        imports = [
          <nixpkgs/nixos/modules/profiles/minimal.nix>
          <nixpkgs/nixos/modules/profiles/headless.nix>
        ];

        environment.systemPackages = [nix qt]; 
        nixpkgs.pkgs = pkgs;
        nix.nixPath = [ "nixpkgs=${pkgs.sources.nixpkgs}" ];
      }; 
    };
    testScript = ''
      startAll

      $machine1->waitForUnit("default.target");
      $machine1->succeed("nix-instantiate --eval --expr '(import <nixpkgs> {}).run-shell'");
    '';
    };
in { 
  smoke.calling-tools = test-scenario;
  shell.able-to-run = basic-shell;
}