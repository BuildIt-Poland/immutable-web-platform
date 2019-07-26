{config, pkgs, lib,...}:
with lib;
# with pkgs;
let
  cfg = config;

  # TODO get packages and traverse it's names
  get-help = pkgs.writeScriptBin "get-help" ''
    echo "You've got in shell some extra spells under your hand ..."
  '';
in
{
  options.environment = {
    type = with types; mkOption {
      default = "local";
      type = enum ["local" "nixos" "brigade"];
    };
    isLocal = mkOption {
      default = true;
    };
  };

  options.shellHook = lib.mkOption {
    default = "";
    type = lib.types.lines;
  };

  options.packages = with types; lib.mkOption {
    default = [];
    type = listOf package;
  };

  options.help = with types; lib.mkOption {
    default = "";
    type = lib.types.lines;
  };

  options.warnings = with types; lib.mkOption {
    default = [];
  };

  options.errors = with types; lib.mkOption {
    default = [];
  };

  config = mkMerge [
    ({
      environment.isLocal = config.environment.type == "local";

      packages = [
        get-help
      ];

      shellHook = ''
        ${pkgs.log.important "Your environment is: ${config.environment.type}"}
        get-help
      '';
    })
  ];
}