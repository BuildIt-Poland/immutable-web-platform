{ nixpkgs, declInput }: let pkgs = import nixpkgs {}; in {
  jobsets = pkgs.runCommand "spec.json" {} ''
    cat <<EOF
    ${builtins.toXML declInput}
    EOF
    cat > $out <<EOF
    {
        "master": {
            "enabled": 1,
            "hidden": false,
            "description": "test",
            "nixexprinput": "nix",
            "nixexprpath": "release.nix",
            "checkinterval": 300,
            "schedulingshares": 100,
            "enableemail": false,
            "emailoverride": "",
            "keepnr": 3,
            "inputs": {
              "src": { "type": "git", "value": "git@bitbucket.org:digitalrigbitbucketteam/embracing-nix-docker-k8s-helm-knative.git nix-docker-image-builder", "emailresponsible": false },
              "nixpkgs": { "type": "git", "value": "git://github.com/NixOS/nixpkgs.git release-19.03", "emailresponsible": false }
            }
        }
    }
    EOF
  '';
}