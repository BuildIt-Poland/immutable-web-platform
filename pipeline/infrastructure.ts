const { events, Job, Group } = require("brigadier")
const { NixJob, extractSecret, saveSecrets, buildNixExpression } = require('brigade-extension')

process.env.BRIGADE_COMMIT_REF = "brigade-resource-generation"

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
    .withEnvVars({
      MY_ENV_VAR: "test"
    })
    .withTasks([
      `cd /src/pipeline`,
      buildNixExpression('shell.nix', 'make-pr-with-descriptors'),
      `./result/bin/make-pr-with-descriptors`,
      // `kubectl get pods -A`
    ])

events.on("exec", (event, project) => {
  let test =
    createJob("test")
      .withSecrets(project.secrets)

  test.run()
})

events.on("push", (event, project) => {
  let test = createJob("test")
    .withSecrets(project.secrets)

  test.run()
})
