{ lib, test, should, stubs, ... }:
let
  pkgs = import ./..;
  integration-modules = ((pkgs {}).callPackage ./default.nix {});
  eval-modules = modules: (integration-modules.eval { inherit modules; });
in
with lib;
with integration-modules.modules;
builtins.concatLists [
  (let
    input = pkgs { inputs.docker.tag = "test"; };
  in (test.run "passing docker tag" input {
    project-config.docker.tag = should.equal "test";
  }))

  (let
    module = {config, ...}: {
      imports = [ project-configuration ];
      config.project.name = "future-is-comming";
    };
    config = eval-modules [module];
  in (test.run "importing project name module" config {
    config.project.name = should.equal "future-is-comming";
  }))

  # TODO think about order
  (let
    moduleA = {config, ...}: {
      imports = [ base ];
      config.warnings = ["Some warning A"];
    };
    moduleB = {config, ...}: {
      imports = [ base ];
      config.warnings = ["Some warning B"];
    };
    config = eval-modules [moduleA moduleB];
  in (test.run "importing project name module" config {
    config.warnings = should.equal ["Some warning B" "Some warning A"];
  }))

  # Action order
  (let
    moduleA = {config, ...}: {
      imports = [ base ];
      config.actions.queue = [{
        priority = config.actions.priority.cluster;
        action = "do_something_A";
      }];
    };
    moduleB = {config, ...}: {
      imports = [ base ];
      config.actions.queue = [{
        priority = config.actions.priority.low;
        action = "do_something_B";
      }];
    };
    config = eval-modules [moduleA moduleB];
  in (test.run "Check actions order" config {
    config.actions.list = should.equal (concatStringsSep "\n" ["do_something_A" "do_something_B"]);
  }))
]