const { events, Job, Group } = require("brigadier")
const { NixJob, saveSecrets, buildNixExpression } = require('brigade-extension')

// process.env.BRIGADE_COMMIT_REF = "bitbucket-integration"

// https://github.com/github/hub

// const _hubCredentials = secrets => `
// cat << EOF > $HOME/.config/hub
// github.com:
//   - protocol: https
//     user: ${secrets.GITHUB_USERNAME}
//     oauth_token: ${secrets.GITHUB_TOKEN}
// EOF
// `;
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
      saveSecrets('secrets.json'),
      `cat secrets.json`,
      buildNixExpression('shell.nix', 'testScript'),
      `./result/bin/test-script`,
      `kubectl get pods -A`
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
