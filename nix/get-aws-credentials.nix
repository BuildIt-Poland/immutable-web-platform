{lib}:
let
  credentials = builtins.readFile ~/.aws/credentials;
  stringArr = lib.splitString "\n" credentials;

  escapeValue = y:
    let
      name = lib.lists.head y;
      value = lib.lists.last y;
    in
      ''${name}="${value}"'';

  breakValues = x:
    let
      values = lib.splitString " = " x;
    in
      if (lib.length values) > 1 
        then (escapeValue values)
        else x;

  escaped = lib.concatStrings (lib.intersperse "\n" (builtins.map breakValues stringArr));
in 
  (fromTOML escaped).default