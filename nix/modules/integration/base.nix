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
      type = enum ["dev" "staging" "qa" "prod"];
    };

    runtime = with types; mkOption {
      default = "local-shell";
      type = enum ["local-shell" "ci-shell"];
    };

    # FIXME remove this
    isLocal = mkOption {
      default = true;
    };

    vars = mkOption {
      default = {};
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
        docker = 150;
        resources = 100;
        low = 0;
      };
    };
    queue = mkOption {
      default = [];
    };
    list = mkOption {
      default = "";
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

  options.binary-store-cache = mkOption {
    default = [];
  };

  # FIXME add module to RUN TESTS agains nix
  options.test = {
    run = with types; mkOption {
      default = "";
    };
    enable = mkOption {
      default = true;
    };
  };

  config = mkMerge [
    ({
      environment.isLocal = config.environment.runtime == "local-shell";

      packages = 
        let
          get-help = pkgs.writeScriptBin "get-help" ''
            ${log.important "You've got in shell some extra spells under your hand ..."}
            ${lib.concatMapStrings log.line config.help}
          '';
        in
        [
          get-help
        ];

      actions.list = 
        let
          sorted-queue = sort (a: b: a.priority > b.priority) config.actions.queue;
          commands-queue = builtins.map (c: c.action) sorted-queue;
        in
          concatStringsSep "\n" commands-queue;

      shellHook = 
        with pkgs;
        let
          pretty-input = 
            lib.generators.toINI {} 
              (inputs // {modules = {};});

          header = ''
            ${log.info "Configuration overridings: \n ${pretty-input}"}
            ${log.info "Nixpkgs version: ${version}"}
            ${log.info "Your environment is: ${config.environment.type}"}
            ${log.info "Your kubernetes target is: ${config.kubernetes.target}"}
            ${log.info "Your build hash is: ${config.project.hash}"}
            ${log.info "Your domain is: ${config.project.domain}"}
            ${log.info "Your runtime is: ${config.environment.runtime}"}
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

          ${config.actions.list}

          ${footer}
        '';
    })
    (mkIf config.test.enable {
      shellHook = ''
        ${pkgs.lib.log.important "Running module tests"}
        ${config.test.run}
      '';
    })
  ];
}