-- options.environment = {
--     type = with types; mkOption {
--       default = "local";
--       type = enum ["dev" "staging" "qa" "prod"];
--     };

--     perspective = with types; mkOption {
--       default = "root";
--       type = enum ["root" "operator" "developer" "ci"];
--     };

--     preload = mkOption {
--       default = false;
--     };

--     vars = mkOption {
--       default = {};
--     };
--   };

--   options.shellHook = mkOption {
--     default = "";
--     type = types.lines;
--   };
let Environment : Type = <DEV | STAGING | UAT | PROD>
let System : Type = {
  environment
}

let makeEnvironment : {}
let greeting = "Hello world"
in {
  greeting = greeting
}