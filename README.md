### Purpose
Yet another story about `kubernetes` and declarative approach to infrastructure.

... being more verbose ... fully automated `kubernetes` environment based on `FaaS` to be run on local environment, virtual machines or in cloud based leveraging `nixos` and `nixpkgs` ecosystem. This is an example architecture how things can be modeled in fully reproducible manner, be language agnostic and 
provide full testing ability of infrastructure as well as on application level following `gitops` way realized by `brigade.js` and `argo cd`.

### Inspiration part
* [brigade js in action](https://www.youtube.com/watch?v=yhfc0FKdFc8&t=1s)
* [knative](https://www.youtube.com/watch?v=69OfdJ5BIzs)
* [brigade & virtual-kubelet](https://cloudblogs.microsoft.com/opensource/2019/04/01/brigade-kubernetes-serverless-tutorial/)
* [gitops](https://www.weave.works/blog/gitops-operations-by-pull-request)
* [argo cd](https://argoproj.github.io/argo-cd/)
* `nix` - [ecosystem](https://www.youtube.com/watch?v=YbUPdv03ciI), [features overview](https://www.youtube.com/watch?v=D5Gq2wkRXpU), [kubernetes](https://www.youtube.com/watch?v=XgZWbrBLP4I)
* [nix - sales pitch](https://gist.github.com/joepie91/9fdaf8244b0a83afcce204e6da127c7d)

### What is super hot!
* development with [`skaffold`](https://github.com/GoogleContainerTools/skaffold)
* gitops - infrastructure and applications described as generated from `nix` `yamls` and stored in `git`
* full determinism of results
* monitoring tools with predefined dashboards
* scale to `0` with `knative & istio`, scale based on concurrency level or resources level
* fully declarative descriptor of environment to provision `local` env, `virtual machine` as well as `clouds` based on `nixpkgs`, `nixops` and `nixOS`

### ... and more
* `helm charts` without `helm` and `tiller`
* pure `nix` solution - there is no any `yaml` file related to descriptor `docker`, `kubernetes` or `helm`
* `nix` in charge of building and pushing docker images to `docker repository`
* full composability of components and configs
* all parts of project are sharable - `nix` is everywhere, in `local` env, `ci worker` or at `system` level - all scripts and libraries can be used in every context
* incremental builds! - if there were no change, artifact, docker or any other thing won't be builded
* diverged targeted builds - `darwin` and `linux` in the same time within nested closures - required for local docker provisioning
* distributed build cache and sharing intermediate states between builds - remote stores to speed up provisioning and `ci` results - work in progress
* `nixops` is provisioning `ec2` or `virtualbox` instances based upon `declarative` nix file
* custom tool to manage remote state for deployments called `remote-state` (check `infra/shell.nix` for usage or it's [docs](/packages/remote-state/README.md))

### Running locally
* download [`nixpkgs`](https://nixos.org/nix/download.html)
* clone this repo
* run `./run-shell-with-worker.sh`

### How to connect the dots
* interactive [mode](https://miro.com/app/board/o9J_kxbrjxg=/)
![architecture](https://bitbucket.org/repo/6zKBnz9/images/83180719-nix-k8s-knative%20%284%29.jpg)

### People are doing it already ...
* [step towards future configuration infrastructure management nix](https://container-solutions.com/step-towards-future-configuration-infrastructure-management-nix/)
* [how we use nix at iohk](https://iohk.io/blog/how-we-use-nix-at-iohk/)

#### Tools comparison
* [ansible vs nix](https://github.com/WeAreWizards/blog/blob/master/content/articles/ansible-and-nix.md)
* [docker vs nix](https://discourse.nixos.org/t/is-there-much-difference-between-using-nix-shell-and-docker-for-local-development/807)

#### Good to familiar with
* [`knative with knctl`](https://developer.ibm.com/blogs/knctl-a-simpler-way-to-work-with-knative/)
* [`docker-containers`](https://github.com/NixOS/nixpkgs/pull/55179)
* [`nixos container`](https://nixos.org/nixos/manual/#ch-containers)
* [`distributed builds`](https://nixos.wiki/wiki/Distributed_build)
* [`nix & docker`](https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/docker/examples.nix)

#### Some articles which were helpful down the road
* [`nix & concourse`](https://memo.barrucadu.co.uk/concourseci-nixos.html)
* [`nix & kubernetes`](https://rzetterberg.github.io/kubernetes-nixos.html)

### Docs
* [How gitops work](/docs/gitops.md)
* [How brigade work](/docs/brigade.md)
* [How cache is handled](/docs/cache.md)
* [How to debug](/docs/debugging.md)
* [How to setup local development](/docs/development.md)
* [What kind of errors you can expect](/docs/errors.md)
* [What I have learnt down the road](/docs/lessons-learnt.md)
* [How secrets are handled](/docs/secrets.md)
* [What is the technology stack](/docs/stack.md)
* [Some tips and tricks](/docs/tips-and-tricks.md)
* [Where I'm and where I want to be](/docs/roadmap.md)
* [Some alternative approaches](/docs/alternatives.md)
* [Cluster monitoring](/docs/monitoring.md)
* [Some good reads](/docs/reads.md)
* [`nix-darwin` and `remote-builders`](/docs/linux-darwin-builds.md)
* [Build `go` package](/docs/building-go-packages.md)

### How to start

#### You need to install these
* get [`docker`](https://www.docker.com/products/docker-desktop) - for [`kind`](https://kind.sigs.k8s.io/)
* get [`nix`](https://nixos.org/nix/download.html) - creating isolated local environment
* run `nix-shell` - if you encounter any issues check [docs](/docs/)

#### Wait for kubernetes
* to check status you can run `kubectl get pods -Aw` - wait until everything will be running

#### Getting all available services
* `minikube service list -p $PROJECT_NAME`

#### Example configuration
```nix
# source ./nix/config/environment-setup.nix

{config, pkgs, lib, kubenix, shell-modules, inputs, ...}: 
with pkgs.lib;
{
  imports = with shell-modules.modules; [
    project-configuration
    kubernetes
    kubernetes-resources
    docker
    brigade
    bitbucket
    git-secrets
    aws
    base
  ];

  config = {
    environment.type = inputs.environment.type;

    project = {
      name = "future-is-comming";
      author-email = "damian.baar@wipro.com";
      version = "0.0.1";
      resources.yaml.folder = "$PWD/resources";
      repositories = {
        k8s-resources = "git@bitbucket.org:damian.baar/k8s-infra-descriptors.git";
        code-repository = "git@bitbucket.org:digitalrigbitbucketteam/embracing-nix-docker-k8s-helm-knative.git";
      };
    };

    test.enable = inputs.tests.enable;

    docker = {
      upload-images-type = ["functions" "cluster"];
      upload = inputs.docker.upload;
      namespace = "dev.local";
      registry = "";
      tag = makeDefault inputs.docker.tag "dev-build";
    };

    aws = {
      location = {
        credentials = ~/.aws/credentials;
        config = ~/.aws/config;
      };
      s3-buckets = {
        worker-cache = "${config.project.name}-worker-binary-store";
      };
    };

    brigade = {
      enabled = true;
      secret-key = inputs.brigade.secret;
      projects = {
        brigade-project = {
          project-name = "embracing-nix-docker-k8s-helm-knative";
          pipeline-file = ../../pipeline/infrastructure.ts; # think about these long paths
          clone-url = config.project.repositories.code-repository;
          ssh-key = config.bitbucket.ssh-keys.priv;
        };
      };
    };

    git-secrets = {
      location = ../../secrets.json;
    };

    kubernetes = {
      cluster.clean = inputs.kubernetes.clean;
      patches.enable = inputs.kubernetes.patches;
      imagePullPolicy = "Never";
      resources = 
        with kubenix.modules;
        let
          functions = (import ./functions.nix { inherit pkgs; });
          resources = config.kubernetes.resources;
          priority = resources.priority;
          # TODO apply skip
          modules = {
            "${priority.high "istio"}"       = [ istio-service-mesh ];
            "${priority.mid  "knative"}"     = [ knative ];
            "${priority.low  "monitoring"}"  = [ weavescope knative-monitoring ];
            "${priority.low  "gitops"}"      = [ argocd ];
            "${priority.low  "ci"}"          = [ brigade ];
            "${priority.low  "secrets"}"     = [ secrets ];
          } // functions;
          in
          {
            apply = inputs.kubernetes.update;
            save = inputs.kubernetes.save;
            list = modules;
          };

      namespace = {
        functions = "functions";
      };
    };

    bitbucket = {
      ssh-keys.location = ~/.ssh/bitbucket_webhook;
    };
  };
}
```

#### Monitoring
* `grafana`
![grafana](https://bitbucket.org/repo/6zKBnz9/images/1943034243-Screenshot%202019-06-19%20at%2013.45.21.png)

* `weavescope`
![weavescope](https://bitbucket.org/repo/6zKBnz9/images/3906895708-Screenshot%202019-06-19%20at%2013.45.55.png)

* `zipkin`
![zipkin](https://bitbucket.org/repo/6zKBnz9/images/573168924-Screenshot%202019-07-10%20at%2013.30.58.png)

#### Gitops
* [ifra repo](https://bitbucket.org/damian_baar/k8s-infra-descriptors/src/master/)
* `argo cd`
![gitops](https://bitbucket.org/repo/6zKBnz9/images/1558410695-Screenshot%202019-07-10%20at%2010.38.17.png)