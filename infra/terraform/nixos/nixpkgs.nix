let 
  system = "x86_64-linux";
  pkgs = (import ../../../nix { 
    inherit system;
  });
  nixpkgs  = pkgs.sources.nixpkgs;
in
  pkgs.runCommand "nixpkgs" {} ''
    ln -sv ${nixpkgs} $out
  ''
