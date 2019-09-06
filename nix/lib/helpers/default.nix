{callPackage}:
{
  findFilesInFolder = callPackage ./find-files-in-folder.nix {};
  log = callPackage ./log.nix {};
  makeDefault = callPackage ./make-default.nix {};
  parseINI = callPackage ./parse-ini.nix {};
  getImageName = callPackage ./get-image-name.nix {};
}