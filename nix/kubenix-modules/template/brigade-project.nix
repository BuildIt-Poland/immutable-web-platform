{config, pkgs, project-config, k8s-resources}:
with pkgs;
let
  namespace = project-config.kubernetes.namespace;
  brigade-ns = namespace.brigade;

  aws = project-config.aws;
  bitbucket = project-config.bitbucket;

  cfg = config.docker.images;
  extension = cfg.brigade-extension;
  worker = cfg.brigade-worker;
in
  {
    project-name ? "",
    clone-url ?  "",
    pipeline-file ? "",
    overridings ? {}
  }:
  {
    namespace = "${brigade-ns}";
    name = project-name;
    chart = k8s-resources.brigade-project;
    # https://github.com/brigadecore/k8s-resources/blob/master/k8s-resources/brigade-project/values.yaml
    values = lib.recursiveUpdate {
      project = project-name;
      repository = project-name; 
      cloneURL = clone-url;
      # repository.location is too long # TODO check if it would work with gateway now ...
      # repository = project-config.repository.location;
      vcsSidecar = "brigadecore/git-sidecar:latest";
      sharedSecret = project-config.brigade.secret-key;
      defaultScript = builtins.readFile pipeline-file; 
      # FIXME: THIS IS INSECURE!!!
      # sshKey = bitbucket.ssh-keys.priv;
      workerCommand = "yarn build-start";
      worker = {
        registry = project-config.docker.registry;
        name = extension.name;
        tag = extension.tag;
        # actually should be never but it seems that they are applying to this policy to sidecar as well
        pullPolicy = "IfNotPresent"; 
      };
      kubernetes = {
        allowSecretKeyRef = "true";
        cacheStorageClass = "cache-storage";
        buildStorageClass = "build-storage";
      };
      secrets = {
        # TODO
        # awsAccessKey = aws.access-key;
        # awsSecretKey = aws.secret-key;
        # THIS is insecure as well!
        # gitToken = bitbucket.ssh-keys.priv;

        gitUser = project-config.project.author-email;
        awsRegion = aws.region;
        sopsSecrets = builtins.readFile project-config.git-secrets.location;
        cacheBucket = aws.s3-buckets.worker-cache;
        workerDockerImage = worker.path;
      };
    } overridings;
  }