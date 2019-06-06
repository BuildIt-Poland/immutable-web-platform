const { events, Job, Group } = require("brigadier")
const { NixJob, saveSecrets, buildNixExpression } = require('brigade-extension')

// process.env.BRIGADE_COMMIT_REF = "bitbucket-integration"

const createJob = (name) =>
  new NixJob(name)
    .withExtraParams({
      streamLogs: true,
      privileged: true,
      shell: 'bash',
    })
    .withTasks([
      `cd /src/pipeline`,
      saveSecrets('secrets.json'),
      `cat secrets.json`,
      buildNixExpression('shell.nix', 'testScript'),
      `./result/bin/test-script`
    ])

events.on("exec", (event, project) => {
  let test = createJob("test")
    .withSecrets(project.secrets)

  test.run()
})

events.on("push", (event, project) => {
  let test = createJob("test")
    .withSecrets(project.secrets)

  test.run()
})
