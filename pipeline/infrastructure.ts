const { events, Job, Group } = require("brigadier")
const { NixJob, extractSecret, saveSecrets, buildNixExpression } = require('brigade-extension')

// TODO think how it can be automated to avoid defining it here
// process.env.BRIGADE_COMMIT_REF = "brigade-resource-generation"

// saveSecrets('secrets.json'),
// `cat secrets.json`,
const createJob = (name) =>
  new NixJob(name)
    .withExtraParams({
      streamLogs: true,
      privileged: true,
      shell: 'bash',
      serviceAccount: "brigade-worker"
    })
    .withTasks([
      `cd /src/pipeline`,
      buildNixExpression('shell.nix', 'make-pr-with-descriptors'),
      `./result/bin/make-pr-with-descriptors`,
      `kubectl get pods -A`
    ])

events.on("exec", (event, project) => {
  let test =
    createJob("test")
      .withSecrets(project.secrets)
      .withEnvVars({
        BUILD_ID: event.buildID || "missing-build-id",
        EVENT: JSON.stringify(event)
      })

  test.run()
})

events.on("push", (event, project) => {
  let test = createJob("test")
    .withSecrets(project.secrets)

  test.run()
})
