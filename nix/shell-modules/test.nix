{ lib, test, should, stubs, ... }:
let
  pkgs = import ./..;
in
builtins.concatLists [
  (let
    input = pkgs { inputs.docker.tag = "test"; };
  in (test.run "passing docker tag" input {
    project-config.docker.tag = should.equal "test";
  }))

  # (test.run "project-name" (pkgs {
  #   inputs.project.name = "future-is-comming2";
  # }) {
  #   inputs.project.name = should.equal "future-is-comming";
  # })
]