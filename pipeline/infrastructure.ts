const { events, Job, Group } = require("brigadier")
const { NixJob, extractSecret, saveSecrets, buildNixExpression } = require('brigade-extension')

process.env.BRIGADE_COMMIT_REF = "brigade-resource-generation"
console.log('@@@', process.env)
// https://github.com/github/hub

// git clone https://bitbucket.org/da20076774/k8s-infra-descriptors

// https://developer.atlassian.com/bitbucket/api/2/reference/resource/repositories/%7Busername%7D/%7Brepo_slug%7D/pullrequests
// remote: upstream
// curl \ 
// -X POST \
// -H "Content-Type: application/json" \
// -u username:password \
//  https://bitbucket.org/api/2.0/repositories/account/reponame/pullrequests \
// -d @pullrequest.json
const mkPR = () => ({
  "title": "Merge some branches",
  "description": "Test PR",
  "source": {
    "branch": {
      "name": "test-pr"
    },
    "repository": {
      "full_name": "da20076774/k8s-infra-descriptors"
    }
  },
  "destination": {
    "branch": {
      "name": "master"
    }
  },
  "close_source_branch": false,
})
// "reviewers": [{ "uuid": "5ca229f597a12b0e40270999" }],
// damian_baar

// const _pushCommit = (cloneURL, buildID) => `
// hub remote add origin ${cloneURL}
// hub push origin update-deployment-${buildID}
// `;

// git config remote.origin.url https://$user:$pass@bitbucket.org/$user/k8s-infra-descriptors.git
const _hubCredentials = () => `
user=$(${extractSecret('bitbucket.user')})
pass=$(${extractSecret('bitbucket.pass')})

git config --global user.email "damian.baar@wipro.com"
git config --global user.name "CI bot"

git clone https://$user:$pass@bitbucket.org/damian_baar/k8s-infra-descriptors.git

cd k8s-infra-descriptors

git checkout -b test-pr
echo "test" > test.file
git add -A
git commit -m "test commit"

git request-pull master ./

git push --set-upstream origin test-pr
git push

curl \
  -X POST \
  -H "Content-Type: application/json" \
  -u $user:$pass \
  https://bitbucket.org/api/2.0/repositories/damian_baar/k8s-infra-descriptors/pullrequests \
  -d '${JSON.stringify(mkPR())}'
`;
// git remote set-url origin https://$user:$pass@bitbucket.org/da20076774/k8s-infra-descriptors.git 
// git request-pull v1.0 https://git.ko.xz/project master
// git config remote.origin.url https://{USERNAME}:{PASSWORD}@github.com/{USERNAME}/{REPONAME}.git


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
      // _hubCredentials(),
      `cd /src/pipeline`,
      buildNixExpression('shell.nix', 'testScript'),
      `./result/bin/test-script`,
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
