// I have to do here some magic to enable runtime transpilation
const { events, Job, Group } = require("brigadier")
const { JobRunner } = require("brigadier/../k8s")
// const { MyJob } = require("brigade-extension")

// TODO add --store property to s3

// const testtest = require('brigade-extension')

const bucket = "future-is-comming-worker-binary-store"

process.env.BRIGADE_COMMIT_REF = "bitbucket-integration"

const XML = require("xml-simple");
const bucketURL = ({ bucket, awsRegion }) => `s3://${bucket}?region=${awsRegion}`;

// dark magic involved
// most likely all these problems are related to nix and mounted PV with noexec option ... need to read more about it
class MyJob extends Job {
  // name: string;

  with(currentEvent, currentProject) {
    this.currentEvent = currentEvent
    this.currentProject = currentProject
    return this
  }

  run() {
    // @ts-ignore
    this.jr = new JobRunner().init(this, this.currentEvent, this.currentProject, process.env.BRIGADE_SECRET_KEY_REF == 'true');
    this._podName = this.jr.name;

    // this.jr.runner.spec.volumes.push({
    //   name: "global-build-storage",
    //   persistentVolumeClaim: {
    //     namespace: "brigade",
    //     claimName: "embracing-nix-docker-k8s-helm-knative-test"
    //   }
    // })

    // this.jr.runner.spec.containers[0].volumeMounts.push(
    //   { name: "global-build-storage", mountPath: "/global" } // as kubernetes.V1VolumeMount
    // );

    return this.jr.run().catch(err => {
      // Wrap the message to give clear context.
      console.error(err);
      let msg = `job ${this.name}(${this.jr.name}): ${err}`;
      return Promise.reject(new Error(msg));
    });
  }
}

function run(e, project) {
  console.log("hello default script")
  // let test = new Job("test", "dev.local/remote-worker:latest")
  let test = new Job("test", "lnl7/nix")
  test.streamLogs = true;
  test.cache.enabled = true;
  test.storage.enabled = true;
  test.docker.enabled = true;

  const { awsAccessKey, awsSecretKey, awsRegion, secrets } = project.secrets
  let job = new MyJob("test", "lnl7/nix")
  job.env = {
    AWS_ACCESS_KEY_ID: awsAccessKey,
    AWS_SECRET_ACCESS_KEY: awsSecretKey,
    AWS_DEFAULT_REGION: awsRegion,
    AWS_PROFILE: '',
    SECRETS: secrets,
    // ...nix,
  }
  job.tasks = [
    // "nix ping-store --store http://remote-worker.brigade:5000",
    // `nix run -f shell.nix testScript -c test-script --option require-sigs false`,
    `echo "require-sigs = false" >> /etc/nix/nix.conf`,
    `echo "binary-caches = ${bucketURL({ bucket, awsRegion })} https://cache.nixos.org/" >> /etc/nix/nix.conf`,
    // `cd /src/pipeline`,
    `cd /src/pipeline`,
    `nix-build shell.nix -A testScript`,
    // `nix-store --repair --verify --check-contents`,
    `nix-store --repair --verify`,
    // // --to local?root=/global \
    // // --to file://global \
    `nix copy \
        --to ${bucketURL({ bucket, awsRegion })}\
        $(nix-store --query --requisites --include-outputs $(nix-store --query --deriver ./result))`,

    `nix-env -i ./result`,
    `nix-env -i sops`,
    `test-script`,

    // should be in image
    // `nix copy \
    //     --to ${bucketURL({ bucket, awsRegion })}\
    //     $(nix-store --query --requisites --include-outputs $(nix-store --query --deriver $(which sops)))`,

    "echo $SECRETS | sops  --input-type json --output-type json -d /dev/stdin > secrets-encrypted.json",
    "cat secrets-encrypted.json"
  ];
  job.streamLogs = true;
  // --option signed-binary-caches "" \

  test.shell = "bash";
  // test.cache.size = "1Gi";
  // test.storage.size = "1Gi";
  test.privileged = true

  // test.useSource = false

  // job.resourceRequests.memory = "2Gi";
  // job.resourceRequests.cpu = "500m";
  // job.resourceLimits.memory = "3Gi";
  // job.resourceLimits.cpu = "1";


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

  XML.parse("<say><to>world</to></say>", (e, say) => {
    console.log(`Saying hello to ${say.to}`)
  })

  const storePath = `${test.storage.path}`
  const storeExport = `${test.cache.path}`
  const resultPath = `$(nix-store --query --requisites --include-outputs $(nix-store --query --deriver ./result))`
  // most likely remote worker would be ok ... 
  test.tasks = [
    "cd /src/pipeline",
    "ls -la",
    // `mkdir -p ${storePath}`,
    // `nix-store --import < ${storeExport}/worker.nar`,
    // `echo "store = ${storePath}" >> /etc/nix/nix.conf`,
    // `ls -la ${test.cache.path}/nix/store`,
    // `echo ${test.cache.path}`, // add nix store
    // `echo ${test.storage.path}`,
    // `echo $NIX_STORE`,
    // `rsync -a --ignore-existing ${storePath}/nix/store /nix/store/`,
    // "nix ping-store --store http://remote-worker.default:5000",
    `ls -la ${storePath}`,
    // `nix-env -i rsync`,
    // `nix run -f shell.nix testScript -c test-script --option require-sigs false`, // --store 's3://${bucket}?region=${awsRegion}&endpoint=example.com'`,
    `mkdir -p ${storePath}/test/test`,
    `mkdir -p ${storeExport}/test/test`,
    `echo ${storePath}`,
    `ls -la ${storePath}`,
    // `rsync -a --ignore-existing /nix/store/ ${storePath}/`
    // `rsync -a --ignore-existing /nix/store/ ${storePath}/`,
    // `ls /nix/store`,
    // `nix-shell --command test-script`,
    // `nix-build shell.nix -A testScript  --option extra-binary-caches 'https://cache.nixos.org' `, // --store 's3://${bucket}?region=${awsRegion}&endpoint=example.com'`,
    // `nix copy \
    //     --to  "file://${storePath}" \
    //     --option narinfo-cache-positive-ttl 0 \
    //     $(nix-store --query --requisites --include-outputs $(nix-store --query --deriver ./result))`,
    // `nix copy --to local?root=${storePath} \
    //   $(nix-store --query --requisites --include-outputs $(nix-store --query --deriver ./result))
    // `
    // `nix-store --export ${resultPath} > ${storePath}/worker.nar`
    // `nix-store --export ${resultPath} > ${storeExport}/worker.nar`

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

  job.with(e, project).run()
  // test.run()
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
