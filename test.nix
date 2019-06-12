# INFO not going to use make-test since it requrie kvm - will be run in kind -> docker
# { nixpkgs }:
# let
#   pkgs = (import ./nix {}).pkgs;
#   testFunction = { pkgs, ... }: {
#     name = "test";

#     nodes = {
#     };

#     testScript = ''
#     '';
#   };
#   nixosTesting = import "${nixpkgs}/lib/testing.nix" {
#     inherit pkgs;
#     system = "x86_64-linux";
#   };
# in nixosTesting.makeTest testFunction

let
  pkgs = (import ./nix {}).pkgs;
  make-test = import "${pkgs.sources.nixpkgs}/nixos/tests/make-test.nix";
in
  make-test {
    nodes = { 
      machine = { ... }: { 
        environment.systemPackages = [ pkgs.env-config ]; 
        }; 
      };

    testScript =
      ''
        $machine->start;
        $machine->waitForUnit("default.target");

        # check that invoking the executable with the `--help` flag is supported
        $machine->succeed("package1-exe --help");
      '';
  }