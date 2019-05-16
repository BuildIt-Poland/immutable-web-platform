{nixpkgs}: 
with nixpkgs;
{
  start-arion = writeScript "start-arion" ''
    #!${bash}/bin/bash
    source /etc/bashrc

    ${arion}/bin/arion \
      --file ${concourse-ci}/arion-compose.nix \
      --pkgs ${concourse-ci}/arion-pkgs.nix \
      up
  '';

  stop-arion = writeScript "stop-arion" ''
    ${arion}/bin/arion \
      --file ${concourse-ci}/arion-compose.nix \
      --pkgs ${concourse-ci}/arion-pkgs.nix \
      rm
  '';
  
  # TODO add logs command

  # https://concourse-ci.org/concourse-generate-key.html
  # https://github.com/concourse/concourse/pull/3330
  generate-keys = writeScript "generate-conckeys" ''
    ssh-keygen -t rsa -f host-key  -N ""
    ssh-keygen -t rsa -f worker-key  -N ""
    ssh-keygen -t rsa -f session-signing-key  -N ""
  '';
}