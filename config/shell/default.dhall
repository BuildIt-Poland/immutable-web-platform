-- let Prelude = https://prelude.dhall-lang.org/package.dhall

let presentWorkingDirectory : Optional Text = Some env:PWD ? None Text
let home : Optional Text = Some env:HOME ? None Text
let FilePath : Type = Text

let Release : Type = {
  , version : Text
}

let Project : Type = {
  , name : Text
  , authorEmail : Text
  , domain : Text
  , rootFolder : FilePath
}

let Repositories : Type = Optional (List { mapKey : Text, mapValue : Text })
-- -- repositories = {
-- --   k8s-resources = "git@bitbucket.org:damian.baar/k8s-infra-descriptors.git";
-- --   code-repository = "git@bitbucket.org:digitalrigbitbucketteam/embracing-nix-docker-k8s-helm-knative.git";
-- -- };
let Repositories = List Text

let AWS = 
  { Type =
    { account : Optional Text
    , location: 
      { credentials: Text
      , config: Optional Text
    }
  }
  , default =
    { account = Some "test"
    , location = 
      { credentials = merge { None = "", Some = \(h: Text) -> "${h}/.aws/credentials"} (home)
      , config = merge { None = "", Some = \(h: Text) -> "${h}/.aws.config"} (home)
      }
    }
  }

let Kubernetes = {
  Type =
    { clean : Optional Bool
    , update : Optional Bool
    , save : Optional Bool
    , patches : Optional Bool
    , tools : Optional Bool
    , resources : Optional FilePath
    }
  , default = 
    { clean = None Bool
    , update = None Bool
    , save = None Bool
    , patches = None Bool
    , tools = None Bool
    , resources = None Text
    }
}

let Kubernetes = 
  { Type = 
  { clean = Some True
  , update = Some True
  , save = Some True
  , patches = Some True
  , tools = Some True
  , resources = merge { None = "", Some = \(pwd: Text) -> "${pwd}/resources"} (presentWorkingDirectory)
  }
  }

-- --     docker = { upload = false; tag = "dev-build"; };

-- let NixModule : Type = {
--   shellHook : List Text
-- }

-- let Docker : Type = {
--   , upload : Bool
--   , tag: Text
-- } -- /\ NixModule

-- let Environment : Type = <LOCAL | DEV | STAGING | UAT | PROD>
-- let Perspective : Type = <ROOT | OPERATOR | DEVELOPER | CI>
-- let Modules : Type = List NixModule
-- let Packages : Type = List Text

-- let System = {
--   Type = {
--     , environment : Environment
--     , release : Release
--     , kubernetes : Kubernetes
--     , perspective : Perspective
--     , packages : List Text
--     , modules : Modules
--   } 
--   -- , default = {
--   --   , environment : Environment.LOCAL
--   --   , perspective : Perspective.ROOT
--   -- }
-- }

-- let test : Docker = {
--   , tag = "test"
--   , upload = True
-- }

-- {lib}:
-- with lib; 
--   recursiveUpdate {
--     environment = { 
--       type = "dev"; 
--       perspective = "root"; 
--       preload = false;
--     };
--     kubernetes = { 
--       target="eks"; 
--       clean = false; 
--       update = false; 
--       save = false; 
--       patches = false; 
--       tools = false;
--     };
--     opa = { validation = false; };
--     docker = { upload = false; tag = "dev-build"; };
--     project = { name = "future-is-comming"; };
--     brigade = { secret = ""; };
--     aws = { region = ""; };
--     tests = {enable = false;};
--     modules = [];
--   }
-- let Inputs : Type =

-- let makeEnvironment : {}
let greeting : Text = "Hello world"
in 
  { greeting = greeting
  ,  AWS = AWS
  }