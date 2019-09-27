{pkgs}:
with pkgs;
rec {
  make-test-docker = import <nixpkgs/nixos/lib/testing.nix> {
    inherit pkgs;
    system = builtins.currentSystem;
  };

  run-docker-test = x: 
    let
      val = (make-test-docker.runTests x.driver).overrideAttrs (_: {
        requiredSystemFeatures = [];
      });
    in
      val;

  make-test-nixos = import <nixpkgs/nixos/tests/make-test.nix>;

  run-scenario = 
    {scenario, args ? {}}: 
      run-docker-test 
        (make-test-docker.makeTest (scenario args));

  make-runnable-tests = {...}@args: lib.mapAttrsRecursive 
    (n: v: 
      if lib.isFunction v
        then run-scenario {scenario = v; inherit args;}
        else v);
}