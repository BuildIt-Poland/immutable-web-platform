const { events, Job, Group } = require("brigadier")
const { NixJob, extractSecret, saveSecrets, buildNixExpression } = require('brigade-extension')

// process.env.BRIGADE_COMMIT_REF = "brigade-resource-generation"

// https://github.com/github/hub

// git clone https://bitbucket.org/da20076774/k8s-infra-descriptors
// echo ${secrets.gitUser}
// echo "${secrets.gitToken}"
const escapePath = (d) => `[\"${d}\"]`
const toSopsPath = (path) => path.split('.').map(escapePath).join('')

// pass="${extractSecret('bitbucket.pass')}"
const _hubCredentials = secrets => `
echo "test"
echo "extracting secrets"
user=$(echo $SECRETS | sops --input-type json -d --extract '${toSopsPath('bitbucket.user')}' -d /dev/stdin)
pass=$(echo $SECRETS | sops --input-type json -d --extract '${toSopsPath('bitbucket.pass')}' -d /dev/stdin)
echo "$(${extractSecret('bitbucket.user')})"
echo $pass
echo $user
git clone https://$user:$pass@bitbucket.org/da20076774/k8s-infra-descriptors.git
`;

const createJob = (name, secrets) =>
  new NixJob(name)
    .withExtraParams({
      streamLogs: true,
      privileged: true,
      shell: 'bash',
      serviceAccount: "brigade-worker"
    })
    .withSecrets(secrets)
    .withTasks([
      _hubCredentials(secrets),
      `cd /src/pipeline`,
      saveSecrets('secrets.json'),
      `cat secrets.json`,
      buildNixExpression('shell.nix', 'testScript'),
      `./result/bin/test-script`,
      `kubectl get pods -A`
    ])

events.on("exec", (event, project) => {
  let test = createJob("test", project.secrets)
  // .withSecrets(project.secrets)

  test.run()
})

events.on("push", (event, project) => {
  let test = createJob("test")
    .withSecrets(project.secrets)

  test.run()
})
