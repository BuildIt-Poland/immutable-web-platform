const { events, Job, Group } = require("brigadier")
const { NixJob, extractSecret, saveSecrets, buildNixExpression, runShellCommand } = require('brigade-extension')

// TODO think how it can be automated to avoid defining it here
process.env.BRIGADE_COMMIT_REF = "nix-modules-refactoring"

// TODO better would be to run shell instead of command -> nix-shell --command make-pr-with-descriptors
const createJob = (name) =>
  new NixJob(name)
    .withExtraParams({
      streamLogs: true,
      privileged: true,
      shell: 'bash',
      serviceAccount: "brigade-worker"
    })
    .withTasks([
      `cd ./pipeline`,
      runShellCommand('make-pr-with-descriptors'),
    ])


events.on("exec", (event, project) => {
  let test =
    createJob("test")
      .withSecrets(project.secrets)
      .withEnvVars({
        BUILD_ID: event.buildID || "missing-build-id",
        EVENT: JSON.stringify(event),
      })

  test.run()
})

events.on("push", (event, project) => {
  let test = createJob("test")
    .withSecrets(project.secrets)

  test.run()
})
