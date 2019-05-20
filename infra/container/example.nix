let
  defaults = {
    autoStart = true;
    privateNetwork = true;
    hostAddress = "192.168.100.10";
  };
in
rec {
  hello = {
    localAddress = "192.168.100.11";
    config = {...}: {
      imports = [ ../services/example/hello-rkt.nix ];
      config.services."hello-rkt".port = 8000;
    };
  } // defaults;

  world = {
    localAddress = "192.168.100.12";
    config = {...}: {
      imports = [ ../services/example/hello-python.nix ];
      config.services."hello-python".port = 8000;
    };
  } // defaults;
}