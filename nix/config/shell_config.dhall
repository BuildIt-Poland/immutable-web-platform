
let presentWorkingDirectory = env:PWD as Text
let home : Optional Text = Some env:HOME ? None Text

let Release : Type = {
  , version : Text
}

let FilePath : Type = Text

let Project : Type = {
  , name : Text
  , authorEmail : Text
  , domain : Text
  , rootFolder : FilePath
}

-- repositories = {
--   k8s-resources = "git@bitbucket.org:damian.baar/k8s-infra-descriptors.git";
--   code-repository = "git@bitbucket.org:digitalrigbitbucketteam/embracing-nix-docker-k8s-helm-knative.git";
-- };
let Repositories = List Text

let AWS = {
  Type: {
    , account : Text
    , location: {
      , credentials: FilePath
      , config: FilePath
    }
  },
  default: {
    location: {
      , credentials: home + ".aws/config"
      , config: home + ".aws/credentials"
    }
  }
}

let Kubernetes : Type = {
  , clean : Bool
  , update : Bool
  , save : Bool
  , patches : Bool
  , tools : Bool
  , resources : FilePath
}

--     docker = { upload = false; tag = "dev-build"; };

let NixModule : Type = {
  shellHook : List Text
}

let Docker : Type = {
  , upload : Bool
  , tag: Text
} // NixModule

let Environment : Type = <LOCAL | DEV | STAGING | UAT | PROD>
let Perspective : Type = <ROOT | OPERATOR | DEVELOPER | CI>
let Modules : Type = List NixModule
let Packages : Type = List Text

let System = {
  Type = {
    , environment : Environment
    , release : Release
    , kubernetes : Kubernetes
    , perspective : Perspective
    , packages : List Text
    , modules : Modules
  } 
  , default = {
    , environment : Environment.LOCAL
    , perspective : Perspective.ROOT
  }
}

let test = Docker::{
  , shellH = ["test"]
  , dsaads = "dsadas"
}

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
let Inputs : Type =

let makeEnvironment : {}
let greeting = "Hello world"
in {
  greeting = greeting
}