# TODO
{
  pkgs
}:
{
  bitbucket-pr-payload = {
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

  # FIXME use eval instead of sed
  make-pr = writeScript "make-pr" ''
    user=$1
    pass=$2
    branch=$3

    payload=$(echo '${builtins.toJSON bitbucket-pr-payload}' \
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
    ${setup-git} 

    user=$(${extractSecret ["bitbucket" "user"]})
    pass=$(${extractSecret ["bitbucket" "pass"]})
    branch="build-$BUILD_ID"

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
}