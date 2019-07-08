const { events, Job, Group } = require("brigadier")
const { NixJob, extractSecret, saveSecrets, buildNixExpression } = require('brigade-extension')

// process.env.BRIGADE_COMMIT_REF = "brigade-resource-generation"

// https://github.com/github/hub

// git clone https://bitbucket.org/da20076774/k8s-infra-descriptors
// echo ${secrets.gitUser}
// echo "${secrets.gitToken}"
const _hubCredentials = secrets => `
echo "test"
echo "extracting secrets"
user="${extractSecret('bitbucket.user')}"
pass="${extractSecret('bitbucket.pass')}"
echo $pass
echo $user
git clone git@bitbucket.org:da20076774/k8s-infra-descriptors.git
git clone https://$user:$pass@bitbucket.org/user/repo.git
`;

// const _hubConfig = (email, name) => `
// hub config --global credential.https://github.com.helper /usr/local/bin/hub-credential-helper
// hub config --global hub.protocol https
// hub config --global user.email "${email}"
// hub config --global user.name "${name}"
// `;

// const _pushCommit = (cloneURL, buildID) => `
// hub remote add origin ${cloneURL}
// hub push origin update-deployment-${buildID}
// `;

// const _pullRequest = (image, buildID) => `
// hub pull-request -F- <<EOF
// Update hello world REST API
// This commit updates the deployment container image to:
//   ${image}
// Build ID:
//   ${buildID}
// EOF
// `;

// _commitImage(image, buildID),
// _pushCommit(project.repo.cloneURL, buildID),
// _pullRequest(image, buildID)

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
