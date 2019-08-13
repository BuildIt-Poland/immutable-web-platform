{
  environment ? null,
  kubernetes ? null,
  brigade ? null,
  docker ? null,
  aws ? null,
  tests ? null
}@inputs:
let
  pkgs = (import ./nix { inherit inputs; }).pkgs;
in
with pkgs;
  mkShell {
    PROJECT_NAME = project-config.project.name;
    # TODO add modules ability to export env vars
    # KUBECONFIG=./terraform/aws/cluster/.kube/kubeconfig_future-is-comming-local
    NIX_SHELL_NAME = "#core-shell";
    
    # FIXME move terraform to infra shell
    buildInputs = [
    ] ++ project-config.packages;
    shellHook= project-config.shellHook;
  }