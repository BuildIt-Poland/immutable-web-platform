{lib, pkgs, kubenix}@args:
{
  helm = {
    chart-from-git = import ./chart-from-git.nix args;
    yaml-to-json = import ./yaml-to-json.nix args;
    yamls-to-json = import ./yamls-to-json.nix args;
    concat-json = import ./concat-json.nix args;
    jsons-to-yaml = import ./jsons-to-yaml.nix args;
    override-static-yaml = import ./override-static-yaml.nix args;
  };
}