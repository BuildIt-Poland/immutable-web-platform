# worker shell
# IMPORTANT: nix is lazy so we can require whole ./nix folder and reuse the scripts - awesome isn't it?
{
  pkgs ? (import ../nix {env = "brigade";})
}:
with pkgs;
let
  build-id = "$BRIGADE_BUILD_NAME";
  branch-name = "build-${build-id}";
  repo-name = "k8s-infra-descriptors";

  bitbucket-pr-payload = {
    title = "Merge some branches";
    description =  "Test PR";
    source.branch.name = "$branch";
    source.repository.full_name = "$user/${repo-name}";
    destination.branch.name = "master";
  };

  clone-repo = writeScriptBin "clone-repo" ''
    git clone https://$user:$pass@bitbucket.org/$user/${repo-name}.git $branch
  '';

  setup-git = writeScript "setup-git" ''
    git config --global user.email "damian.baar@wipro.com"
    git config --global user.name "CI bot"
  '';

  create-pr-branch = writeScript "create-pr-branch" ''
    git checkout -b $branch
  '';

  show-changes-diff = writeScript "show-git-diff" ''
    git request-pull master ./
  '';

  copy-resources = writeScript "copy-resources" ''
    cat ${pkgs.k8s-cluster-operations.resources.yaml.cluster} > cluster.yaml
    cat ${pkgs.k8s-cluster-operations.resources.yaml.functions} > resources.yaml
  '';

  create-branch-with-descriptors = writeScript "create-branch-with-descriptors" ''
    ${copy-resources}
    git add -A
    git commit -m "Applying resources for release: ${pkgs.env-config.version}, build: $BRIGADE_BUILD_ID"

    ${show-changes-diff}
  '';

  push-branch = writeScript "push-branch" ''
    git push --set-upstream origin ${branch-name}
    git push
  '';

  make-pr = writeScript "make-pr" ''
    curl \
      -X POST \
      -H "Content-Type: application/json" \
      -u $user:$pass \
      https://bitbucket.org/api/2.0/repositories/$user/${repo-name}/pullrequests \
      -d '${builtins.toJSON bitbucket-pr-payload}'
  '';
  
  #######
  # SOPS
  #######
  get-path = path:
    builtins.concatStringsSep ""
      (builtins.map (x: ''["${x}"]'') path);

  extractSecret = path: pkgs.writeScript "extract-secret" ''
    echo $SECRETS | sops --input-type json -d --extract '${get-path path}' -d /dev/stdin
  '';

  repo = "k8s-infra-descriptors";

  # TODO change test-scripts to more meaningfull name ...
  push-descriptors-to-git = pkgs.writeScript "test-script" ''
    ${setup-git} 

    user=$(${extractSecret ["bitbucket" "user"]})
    pass=$(${extractSecret ["bitbucket" "pass"]})
    branch=${build-id}

    ${clone-repo}
    cd ${branch-name}
    ${create-branch-with-descriptors}
    ${push-branch}
    ${make-pr}
  '';

  testScript = pkgs.stdenv.mkDerivation {
    name = "test-script";
    src = ./.;
    phases = ["installPhase"];
    buildInputs = [];
    preferLocalBuild = true;
    nativeBuildInputs = [];
    installPhase = ''
      mkdir -p $out/bin
      cp ${push-descriptors-to-git} $out/bin/${push-descriptors-to-git.name}
    '';
  };
in
with pkgs; 
{ 
  inherit testScript;

  shell = mkShell {
    SECRETS = builtins.readFile ../secrets.json;

    buildInputs = [
      testScript
    ];

    shellHook= ''
      echo "hey hey hey worker"
    '';
  };
}