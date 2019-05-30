const { events, Job } = require("brigadier");

function run(e, project) {
  console.log("hello default script")
  let test = new Job("test", "lnl7/nix:latest")

  const { awsAccessKey, awsSecretKey, awsRegion, secrets } = project.secrets

  test.env = {
    AWS_ACCESS_KEY_ID: awsAccessKey,
    AWS_SECRET_ACCESS_KEY: awsSecretKey,
    AWS_DEFAULT_REGION: awsRegion,
    SECRETS: secrets
  }

  test.tasks = [
    "ls -la /src",
    "nix-env -i hello",
    "nix-env -i sops",
    "hello",
    "cd src",
    "echo $AWS_ACCESS_KEY_ID",
    "echo $AWS_SECRET_ACCESS_KEY",
    "echo $SECRETS"
    // "docker login -u $DOCKER_USER -p $DOCKER_PASS",
  ];
  // "nix-build nix -A cluster-stack.push-to-docker-registry"
  // // nix-run

  test.streamLogs = true;

  test.run()
}

events.on("exec", run)
events.on("push", function (e, project) {
  console.log("received push for commit " + e.revision.commit)
  console.log(e.payload)
  var gh = JSON.parse(e.payload)
  var test = new Job("test", "alpine:3.4")

  test.tasks = [
    "ls -la",
    "echo hello",
    "ls -la /src",
  ];
  test.run()
})
