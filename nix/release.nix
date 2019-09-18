{ src ? ./., ... }: 
let 
  pkgs = import nixpkgs {}; 
  _pkgs = (import src { inputs = {
    environment = {
      type = "dev"; 
      perspective = "release";
    };
  }; }).pkgs;
in {
  hello = _pkgs.hello;
  brigadeterm = _pkgs.brigadeterm;
  istioctl = _pkgs.istioctl;
}