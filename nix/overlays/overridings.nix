{sources}:
self: super: rec {
  minikube = 
    (super.runCommand "minikube-wrapper" 
      { buildInputs = [ super.makeWrapper ]; } '' 
        mkdir -p $out/bin
        makeWrapper ${super.minikube}/bin/minikube $out/bin/minikube \
          --add-flags "-p ${super.pkgs.project-config.kubernetes.cluster.name}"
      '');

  # INFO alternative way
  # pkgs.hello.overrideAttrs (oldAttrs: {
  #   buildInputs = oldAttrs.buildInputs or [] ++ [ pkgs.makeWrapper ];
  #   postInstall = oldAttrs.postInstall or "" + ''
  #     wrapProgram $out/bin/hello \
  #       --add-flags "-t"
  #   '';
  # })
}