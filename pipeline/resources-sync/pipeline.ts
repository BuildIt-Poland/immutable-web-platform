const { events, Job, Group } = require("brigadier")
const { NixJob, extractSecret, saveSecrets, buildNixExpression, runShellCommand } = require('brigade-extension')

// TODO prepare script
// brig run -f pipeline/infrastructure.ts <project_name> --ref <branch>

console.log(process.env)

const createJob = (name) => {
  let t = new NixJob(name)
    .withExtraParams({
      streamLogs: true,
      privileged: true,
      annotations: {
        "iam.amazonaws.com/allowed-roles": "[\"*future-is-comming*\"]"
      },
      shell: 'bash',
      serviceAccount: "brigade-worker"
    })

  t = t.withTasks([
    runShellCommand('release-tools'),
  ])

  return t
}

events.on("exec", async (event, project) => {
  console.log('@@@', event, project)
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

  await test.run()
})

events.on("push", (event, project) => {
  let test = createJob("test")
    .withSecrets(project.secrets)

  test.run()
})
