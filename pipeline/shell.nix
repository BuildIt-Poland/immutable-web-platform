# worker shell
# IMPORTANT: nix is lazy so we can require whole ./nix folder and reuse the scripts - awesome isn't it?
{
  pkgs ? (import ../nix { 
    inputs = {
      environment.type = "brigade"; 
      tests.enable = false;
      kubernetes = {
        save = false;
        patches = false;
      };
    };
  })
}:
with pkgs;
let
  repo-name = "k8s-infra-descriptors";

  #######
  # GIT
  #######

  bitbucket-pr-payload = {
    title = "Kubernetes update";
    description =  "CI build";
    source.branch.name = "$branch";
    source.repository.full_name = "$user/${repo-name}";
    destination.branch.name = "master";
  };

  clone-repo = writeScript "clone-repo" ''
    user=$1
    pass=$2
    branch=$3

    git clone https://$user:$pass@bitbucket.org/$user/${repo-name}.git $branch
  '';

  setup-git = writeScript "setup-git" ''
    git config --global user.email "damian.baar@wipro.com"
    git config --global user.name "CI bot"
  '';

  create-pr-branch = writeScript "create-pr-branch" ''
    branch=$1
    git checkout -b $branch
  '';

  show-changes-diff = writeScript "show-git-diff" ''
    git request-pull master ./
  '';

  commit-descriptors = writeScript "commit-descriptors" ''
    git add -A
    git commit -m "Applying resources for release: ${pkgs.project-config.project.version}, build id: $BUILD_ID"
  '';

  push-branch = writeScript "push-branch" ''
    branch=$1
    git push --set-upstream origin $branch
    git push
  '';

  make-pr = writeScript "make-pr" ''
    user=$1
    pass=$2
    branch=$3

    payload=$(echo '${builtins.toJSON bitbucket-pr-payload}' \
             | sed -e 's/$user/'"$user"'/g' -e 's/$branch/'"$branch"'/g')

    curl \
      -X POST \
      -H "Content-Type: application/json" \
      -u $user:$pass \
      https://bitbucket.org/api/2.0/repositories/$user/${repo-name}/pullrequests \
      -d "$payload"
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

  push-descriptors-to-git = pkgs.writeScript "make-pr-with-descriptors" ''
    ${setup-git} 

    user=$(${extractSecret ["bitbucket" "user"]})
    pass=$(${extractSecret ["bitbucket" "pass"]})
    branch="build-$BUILD_ID"

    echo from secrets $user
    echo from secrets $pass

    ${clone-repo} $user $pass $branch
    cd $branch
    ${create-pr-branch} $branch

    mkdir -p resources
    ${pkgs.k8s-operations.save-resources}/bin/save-resources
    ${commit-descriptors}
    ${push-branch} $branch
    ${show-changes-diff}
    ${make-pr} $user $pass $branch
  '';

  make-pr-with-descriptors = pkgs.stdenv.mkDerivation {
    name = "make-pr-with-descriptors";
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
  inherit make-pr-with-descriptors;

  shell = mkShell {
    SECRETS = builtins.readFile ../secrets.json;
    PROJECT_NAME = project-config.project.name;

    buildInputs = [ make-pr-with-descriptors ] ++ project-config.packages;
    shellHook= project-config.shellHook;
  };
}