{
  pkgs
}:
let
  sops = pkgs.callPackage ./sops.nix {};
  prj = pkgs.project-config;
  email = prj.project.authorEmail;
  repo-name = prj.bitbucket.k8s-resources.repository;
  version = prj.project.version;
in
with pkgs;
# FIXME refactor this module
rec {
  pr-payload = {
    title = "Kubernetes update";
    description =  "$description";
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
    git config --global user.email "${email}"
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
    git commit -m "Applying resources for release: ${version}, build id: $BUILD_ID"
  '';

  push-branch = writeScript "push-branch" ''
    branch=$1
    git push --set-upstream origin $branch
    git push
  '';

  # FIXME use eval instead of sed
  make-pr = writeScript "make-pr" ''
    user=$1
    pass=$2
    branch=$3

    payload=$(echo '${builtins.toJSON pr-payload}' \
             | sed -e 's/$user/'"$user"'/g' \
                   -e 's/$branch/'"$branch"'/g' \
                   -e 's/$description/CI build: '"$BUILD_ID"'/g'
                   )

    curl \
      -X POST \
      -H "Content-Type: application/json" \
      -u $user:$pass \
      https://bitbucket.org/api/2.0/repositories/$user/${repo-name}/pullrequests \
      -d "$payload"
  '';
  
  push-descriptors-to-git = pkgs.writeScript "make-pr-with-descriptors" ''
    user=$1
    pass=$2
    branch=$3

    ${setup-git} 

    ${clone-repo} $user $pass $branch
    cd $branch
    ${create-pr-branch} $branch

    mkdir -p resources
    ${pkgs.k8s-operations.save-resources}/bin/save-resources
    ${commit-descriptors}
    ${push-branch} $branch
    ${show-changes-diff}
  '';

  push-k8s-resources-to-repo = pkgs.writeScriptBin "push-k8s-resources-to-repo" ''
    user=$(${sops.extractSecret ["bitbucket" "user"]})
    pass=$(${sops.extractSecret ["bitbucket" "pass"]})
    branch="build-$BUILD_ID"

    ${push-descriptors-to-git} $user $pass $branch
    ${make-pr} $user $pass $branch
  '';
}