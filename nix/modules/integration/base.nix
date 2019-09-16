{config, pkgs, inputs, lib,...}:
with lib;
let
  cfg = config;

  skip-functions = lib.filterAttrsRecursive (n: v: !(lib.isFunction v));
  # TODO get packages and traverse it's names
in
{
  options.environment = {
    type = with types; mkOption {
      default = "local";
      type = enum ["dev" "staging" "qa" "prod"];
    };

    perspective = with types; mkOption {
      default = "root";
      type = enum ["root" "operator" "developer" "builder"];
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

  options.output = mkOption {
    default = {};
  };

  options.save-output = mkOption {
    default = true;
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
            ${log.info "Your runtime perspective is: ${config.environment.perspective}"}
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

    (mkIf config.save-output {
      packages = 
      let
        config-string = 
          builtins.toJSON (skip-functions cfg.output);
      in
      [
        (pkgs.writeScriptBin "save-config" ''
          echo '${config-string}' | ${pkgs.jq}/bin/jq . > config.${cfg.environment.type}.json
        '')
      ];

      actions.queue = [
        { priority = cfg.actions.priority.low; 
          action = ''
            save-config
          '';
        }
      ];
    })
  ];
}