let
  nixpkgs = <nixpkgs>;
  pkgs = import nixpkgs {};
  make-test = import "${nixpkgs}/nixos/tests/make-test.nix";
in make-test {
  name = "test";

  nodes = { 
    machine = { ... }: { 
      environment.systemPackages = [ pkgs.bash ]; 
    }; 
  };

  testScript = ''
    $machine->start;
    $machine->waitForUnit("default.target");
    $machine->succeed("echo 'test'");
  '';
}