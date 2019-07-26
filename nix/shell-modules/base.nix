{config, pkgs, inputs, lib,...}:
with lib;
let
  cfg = config;

  # TODO get packages and traverse it's names
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

  options.shellHook = mkOption {
    default = "";
    type = types.lines;
  };

  options.actions = {
    priority = mkOption {
      default = {
        cluster = 300;
        crd = 200;
        resources = 100;
        low = 0;
      };
    };
    queue = mkOption {
      default = [];
    };
  };

  options.packages = with types; mkOption {
    default = [];
    type = listOf package;
  };

  options.checks = with types; mkOption {
    default = [];
  };

  options.help = with types; mkOption {
    default = [];
  };

  options.infos = with types; mkOption {
    default = [];
  };

  options.warnings = with types; mkOption {
    default = [];
  };

  options.errors = with types; mkOption {
    default = [];
  };

  config = mkMerge [
    ({
      environment.isLocal = config.environment.type == "local";

      packages = 
        let
          get-help = pkgs.writeScriptBin "get-help" ''
            ${pkgs.log.important "You've got in shell some extra spells under your hand ..."}
            ${lib.concatMapStrings pkgs.log.line config.help}
          '';
        in
        [
          get-help
        ];

      shellHook = 
        with pkgs;
        let
          sorted-queue = sort (a: b: a.priority > b.priority) config.actions.queue;
          commands-queue = builtins.map (c: c.action) sorted-queue;
          commands-string = concatStringsSep "\n" commands-queue;
          pretty-input = lib.generators.toINI {} inputs;

          header = ''
            ${log.info "Input configuration: \n ${pretty-input}"}
            ${log.info "Nixpkgs version: ${version}"}
            ${log.info "Your environment is: ${config.environment.type}"}
          '';

          footer = ''
            echo "Run 'get-help' to get all available commands"
          '';
        in
        ''
          ${header}

          ${lib.concatMapStrings log.ok config.checks}
          ${lib.concatMapStrings log.info config.infos}
          ${lib.concatMapStrings log.warn config.warnings}
          ${lib.concatMapStrings log.error config.errors}

          ${commands-string}

          ${footer}
        '';
    })
  ];
}