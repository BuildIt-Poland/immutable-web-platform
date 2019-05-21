{
  pkgs, 
  stdenv,
  env-config, 
  callPackage,
  runCommand,
  writeScript,
  kubenix,
  lib
}:
with kubenix.lib;
rec {
  config = callPackage ./config.nix {};
  result = k8s.mkHashedList { items = config.kubernetes.objects; };
  yaml = toYAML result;

  apply-cluster-stack = writeScript "apply-cluster-stack" ''
    echo "Applying helm charts"
    cat ${yaml} | ${pkgs.kubectl}/bin/kubectl apply -f -
  '';

  init = stdenv.mkDerivation {
    name = "init-cluster-stack";
    version = env-config.version;
    src = ./.;
    phases = ["installPhase"];
    buildInputs = [];
    installPhase = ''
      mkdir -p $out/bin
      cp ${apply-cluster-stack} $out/bin/${apply-cluster-stack.name}
    '';
  };
}
