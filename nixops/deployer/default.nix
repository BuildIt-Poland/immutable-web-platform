{
  pkgs,
  paths,
  local
}: 
with pkgs;
with remote-state.package;
let
  state-locker = remote-state-cli;

  keep-nixops-stateless = pkgs.writeScript "keep-it-stateless" ''
    rm ${paths.state-sql}
  '';

  nixops-export-state = pkgs.writeScript "nixops-export-state" ''
    ${pkgs.nixops}/bin/nixops export --all
  '';

  nixops-import-state = pkgs.writeScript "nixops-import-state" ''
    ${pkgs.nixops}/bin/nixops import --include-keys
  '';

  import-remote-state = pkgs.writeScript "import-remote-state" ''
    ${state-locker}/bin/locker import-state \
      --from "${nixops-export-state}" \
      --before-to "${keep-nixops-stateless}" \
      --to "${nixops-import-state}"
  '';

  upload-remote-state = pkgs.writeScript "upload-remote-state" ''
    ${state-locker}/bin/locker upload-state \
      --from "${pkgs.nixops}/bin/nixops export --all"
  '';

  # TODO make it better ...
  # issue: when running ssh with nix shell as argument escaping should not be applied since is on remote machine
  nixops-wrapped = pkgs.writeScript "nixops" ''
    ${if local 
      then ''${pkgs.nixops}/bin/nixops $*''
      else ''${pkgs.nixops}/bin/nixops $(${state-locker}/bin/locker rewrite-arguments --input "$*" --cwd $(pwd))''
    }
  '';
in
  stdenv.mkDerivation {
    name = "nixops-remote-deployer";

    buildInputs = [
      remote-state-cli
      nixops
    ];

    phases = ["installPhase"];

    installPhase = ''
      mkdir -p $out/bin
      cp ${nixops-wrapped} $out/bin/${nixops-wrapped.name}
      cp ${import-remote-state} $out/bin/${import-remote-state.name}
      cp ${upload-remote-state} $out/bin/${upload-remote-state.name}
    '';
  }