const { events, Job, Group } = require("brigadier")
const { NixJob, saveSecrets, buildNixExpression } = require('brigade-extension')

process.env.BRIGADE_COMMIT_REF = "bitbucket-integration"

const createJob = (name) =>
  new NixJob(name)
    .withExtraParams({
      streamLogs: true,
      privileged: true,
      cache: { enabled: true },
      storage: { enabled: true },
      docker: { enabled: true },
    })
    .withTasks([
      `cd /src/pipeline`,
      saveSecrets('secrets.json'),
      `cat secrets.json`,
      buildNixExpression('shell.nix', 'testScript'),
    ])

events.on("exec", (event, project) => {
  let test = createJob("test")
    .withProject(project)
    .withEvent(event)
    .withEnvVars({})

  test.run()
})

events.on("push", (event, project) => {
  let test = createJob("test")
    .withProject(project)
    .withEvent(event)

  test.run()
})
