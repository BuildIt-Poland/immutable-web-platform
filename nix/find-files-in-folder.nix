{ lib }:
# FilePath -> String -> String -> {[Folder]: FilePath}
# i.e find-files-in-folder rootFolder "/functions" "nix/default.nix";
# { express-app = <rootFolder>/functions/express-app/nix/default.nix; }
let
  findFileInFolders = root: dirToCheck: file:
    let
      directory = root + "/${dirToCheck}";
      workspacesDir = builtins.readDir directory;
      onlyDirs = lib.filterAttrs (x: y: y == "directory") workspacesDir;
      onlyDirNames = builtins.attrNames onlyDirs;
      dirsPaths = builtins.map (x: { "${baseNameOf x}" = directory + "/${x}/${file}"; }) onlyDirNames;
      onlyExisting = builtins.filter (f: lib.pathExists (builtins.elemAt (builtins.attrValues f) 0)) dirsPaths;
    in
      lib.foldl (lib.mergeAttrs) {} onlyExisting;
in
  findFileInFolders