const { events, Job } = require("brigadier")

// TODO add --store property to s3

const bucket = "future-is-comming-binary-store"

process.env.BRIGADE_COMMIT_REF = "bitbucket-integration"

const bucketURL = ({ bucket, awsRegion }) => `s3://${bucket}?region=${awsRegion}`;

function run(e, project) {
  console.log("hello default script")
  let test = new Job("test", "lnl7/nix:latest")
  test.streamLogs = true;
  test.cache.enabled = true;
  test.storage.enabled = true;

  test.shell = "bash";
  test.cache.size = "1Gi";
  test.storage.size = "1Gi";
  test.privileged = true

  // job.resourceRequests.memory = "2Gi";
  // job.resourceRequests.cpu = "500m";
  // job.resourceLimits.memory = "3Gi";
  // job.resourceLimits.cpu = "1";

  const { awsAccessKey, awsSecretKey, awsRegion, secrets } = project.secrets

  const nix = {
    // NIX_STORE_DIR: `${test.cache.path}/nix/store`,
    // NIX_STATE_DIR: `${test.cache.path}/nix/state`,
    // NIX_DB_DIR: `${test.cache.path}/nix/db`
  };

  test.env = {
    AWS_ACCESS_KEY_ID: awsAccessKey,
    AWS_SECRET_ACCESS_KEY: awsSecretKey,
    AWS_DEFAULT_REGION: awsRegion,
    AWS_PROFILE: '',
    SECRETS: secrets,
    // ...nix,
  }

  const storePath = `${test.cache.path}/nix/store`
  // most likely remote worker would be ok ... 
  test.tasks = [
    "cd /src/pipeline",
    "ls -la",
    // `rm -rf ${storePath}`,
    `echo "store = ${storePath}" >> /etc/nix/nix.conf`,
    // `ls -la ${test.cache.path}/nix/store`,
    // `echo ${test.cache.path}`, // add nix store
    // `echo ${test.storage.path}`,
    // `echo $NIX_STORE`,
    `nix-env -i bash`,
    `nix-shell --command test-script`,
    // `nix-build shell.nix -A testScript  --option extra-binary-caches 'https://cache.nixos.org' `, // --store 's3://${bucket}?region=${awsRegion}&endpoint=example.com'`,
    // `nix copy \
    //     --to  "file://${storePath}" \
    //     --option narinfo-cache-positive-ttl 0 \
    //     $(nix-store --query --requisites --include-outputs $(nix-store --query --deriver ./result))`,
    // `nix copy --option signed-binary-caches '*' --to local?root=${storePath} $(which bash) --no-check-sigs`

    // `nix-store --store ${bucketURL({ bucket, awsRegion })}`,
    // "nix-env -i curl --option extra-binary-caches 'http://remote-worker.default:5000/ https://cache.nixos.org' --substituters http://remote-worker.default:5000/",
    // "nix ping-store --store http://remote-worker.default:5000"
    // `nix-build shell.nix -A testScript --option signed-binary-caches "" --option extra-binary-caches 'https://s3.eu-west-2.amazonaws.com/future-is-comming-binary-store https://cache.nixos.org' --substituters 'http://remote-worker.default:5000/'`, // --store 's3://${bucket}?region=${awsRegion}&endpoint=example.com'`,
    // "curl http://remote-worker.default:5000/nix-cache-info"
    // `nix-build shell.nix -A testScript --option extra-binary-caches 'https://s3.eu-west-2.amazonaws.com/future-is-comming-binary-store https://cache.nixos.org/'`, // --store 's3://${bucket}?region=${awsRegion}&endpoint=example.com'`,
    // `nix copy --option signed-binary-caches="" --no-check-sigs --all --to "s3://${bucket}?region=${awsRegion}"`, // all
    // `nix copy \
    //     --to  "s3://${bucket}?region=${awsRegion}" \
    //     --option narinfo-cache-positive-ttl 0 \
    //     $(nix-store --query --requisites --include-outputs $(nix-store --query --deriver ./result))`,

    // `./result/bin/test-script`
    // `nix-shell --run test-script --store 's3://${bucket}?region=${awsRegion}'`
  ];
  // "echo $SECRETS | sops  --input-type json --output-type json -d /dev/stdin > secrets-encrypted.json",
  // "cat secrets-encrypted.json"
  // "nix-build nix -A cluster-stack.push-to-docker-registry"
  // // nix-run


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
