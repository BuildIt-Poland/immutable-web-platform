const { events, Job, Group } = require("brigadier")
const { NixJob, extractSecret, saveSecrets, buildNixExpression, runShellCommand } = require('brigade-extension')

// TODO prepare script
// brig run -f pipeline/infrastructure.ts <project_name> --ref <branch>

//#Node-Selectors:  beta.kubernetes.io/os=linux 
// this.host.nodeSelector["kubernetes.io/lifecycle"] = "spot"
const createJob = (name) => {
  let t = new NixJob(name)
    .withExtraParams({
      streamLogs: true,
      privileged: true,
      annotations: {
        // kube2iam
        "backup.velero.io/backup-volumes": "brigade-data"
      },
      shell: 'bash',
      serviceAccount: "brigade-worker"
    })

  t = t.withTasks([
    `cat ${t.cache.path}/test.file`,
    `cat ${t.cache.path}/test2.file`,
    `echo "storage" > ${t.storage.path}/test.file`,
    `echo "cache 1" > ${t.cache.path}/test.file`,
    `echo "cache 2" > ${t.cache.path}/test2.file`,
    // `cat ${t.storage.path}/test.file`,
    `cd /src`,
    `./nix/run-tests.sh`
    // runShellCommand('push-k8s-resources-to-repo'),
  ])

  return t
}

events.on("exec", async (event, project) => {
  let test =
    createJob("test")
      .withSecrets(project.secrets)
      .withEnvVars({
        BUILD_ID: event.buildID || "missing-build-id",
        EVENT: JSON.stringify(event),
      })

  let test2 =
    createJob("test2")
      .withSecrets(project.secrets)
      .withEnvVars({
        BUILD_ID: event.buildID || "missing-build-id",
        EVENT: JSON.stringify(event),
      })

  test2 = test2
    .withTasks([
      `cat ${test2.storage.path}/test.file`,
      // `cat ${test2.cache.path}/test.file`,
    ])
  // i don't like it, not sure how to attach nodeSelector
  // https://github.com/brigadecore/brigade/blob/master/brigade-worker/src/k8s.ts#L393
  // test.host.name = "spot"
  // test.host.os = "linux"

  // test.run()
  await test.run()
  await test2.run()
})

// TODO
events.on("push", (event, project) => {
  let test = createJob("test")
    .withSecrets(project.secrets)

  test.run()
})
