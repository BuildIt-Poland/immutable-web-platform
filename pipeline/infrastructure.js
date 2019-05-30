const { events, Job } = require("brigadier")

// TODO add --store property to s3

const bucket = "future-is-comming-binary-store"

process.env.BRIGADE_COMMIT_REF = "bitbucket-integration"

function run(e, project) {
  console.log("hello default script")
  let test = new Job("test", "lnl7/nix:latest")

  const { awsAccessKey, awsSecretKey, awsRegion, secrets } = project.secrets

  test.env = {
    AWS_ACCESS_KEY_ID: awsAccessKey,
    AWS_SECRET_ACCESS_KEY: awsSecretKey,
    AWS_DEFAULT_REGION: awsRegion,
    AWS_PROFILE: '',
    SECRETS: secrets
  }

  test.tasks = [
    "cd /src/pipeline",
    "ls -la",
    `nix-build shell.nix -A testScript`,

    `nix copy \
        --to  "s3://our-nix-cache-bucket-name?profile=our-profile-name&endpoint=our.endpoint.example.com" \
        --option narinfo-cache-positive-ttl 0 \
        $(nix-store --query --requisites --include-outputs $(nix-store --query --deriver ./result))`,

    `./result/bin/test-script`
    // `nix-shell --run test-script --store 's3://${bucket}?region=${awsRegion}'`
  ];
  // "echo $SECRETS | sops  --input-type json --output-type json -d /dev/stdin > secrets-encrypted.json",
  // "cat secrets-encrypted.json"
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
