const { events, Job, Group } = require("brigadier")
const { NixJob, extractSecret, saveSecrets, buildNixExpression, runShellCommand } = require('brigade-extension')

// TODO think how it can be automated to avoid defining it here
process.env.BRIGADE_COMMIT_REF = "nix-modules-refactoring"

const createJob = (name) =>
  new NixJob(name)
    .withExtraParams({
      streamLogs: true,
      privileged: true,
      shell: 'bash',
      serviceAccount: "brigade-worker"
    })
    .withTasks([
      // `AWS_ACCESS_KEY_ID="$(echo $AWS_ACCESS_KEY_ID | tr -d "\n")"`,
      // `AWS_SECRET_ACCESS_KEY=$(echo $AWS_SECRET_ACCESS_KEY | tr -d "\n")`,
      `echo "$AWS_ACCESS_KEY_ID test test"`,
      `echo $AWS_SECRET_ACCESS_KEY`,
      runShellCommand('push-k8s-resources-to-repo'),
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
