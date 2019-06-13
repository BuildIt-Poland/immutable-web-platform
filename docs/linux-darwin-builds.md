### on darwin when running docker-images it is required to have a linux worker
* simply run `run-linux-worker.sh`


### nix-darwin
* other option is to install https://github.com/LnL7/nix-darwin
```nix

  nix.buildMachines = [
    {
      hostName = "nix-docker-build-slave";
      systems = [ "x86_64-linux" ];
      maxJobs = 2;
      supportedFeatures = ["nixos-test" "big-parallel" "benchmark"];
    }
    {
      hostName = "localhost";
      systems = [ "x86_64-darwin" ];
      maxJobs = 6;
      supportedFeatures = ["nixos-test" "big-parallel" "benchmark"];
    }
  ];
```