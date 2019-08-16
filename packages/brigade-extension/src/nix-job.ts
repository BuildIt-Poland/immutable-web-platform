import { Job } from '@brigadecore/brigadier'
// IMPORTANT: from here we can take only types since brigade is doing runtime override
// I have to suggest them to use runInVm and pass the context rather than overriding runtime ...
import { Project, BrigadeEvent } from '@brigadecore/brigadier/out/events'
import { Result } from '@brigadecore/brigadier/out/job'

export type WorkerSecrets = {
  workerDockerImage: string
  // awsAccessKey: string
  // awsSecretKey: string
  awsRegion: string
  cacheBucket: string
  sopsSecrets: {
    docker: {
      user: string
      pass: string
    },
    bitbucket: {
      user: string
      pass: string
      hook: string
    }
  }
}

export type NixProject = Project & { secrets: WorkerSecrets }
export type Secrets = WorkerSecrets & Record<string, string>

export const bucketURL = ({ cacheBucket, awsRegion }) =>
  `s3://${cacheBucket}?region=${awsRegion}`

const applyNixConfig = ({ cacheBucket, awsRegion }) => [
  `echo "require-sigs = false" >> /etc/nix/nix.conf`,
  `echo "binary-caches = ${bucketURL({ cacheBucket, awsRegion })} https://cache.nixos.org/" >> /etc/nix/nix.conf`
]

export const saveSecrets = (fileName: string = 'secrets-encrypted.json') => [
  `echo $SECRETS | sops --input-type json --output-type json -d /dev/stdin > ${fileName}`,
]

// https://github.com/mozilla/sops#45extract-a-sub-part-of-a-document-tree
const escapePath = (d) => `[\"${d}\"]`
const toSopsPath = (path: string) => path.split('.').map(escapePath).join('')

// i.e. extractSecret('docker.pass')
export const extractSecret = (path: string) =>
  `echo $SECRETS | sops --input-type json -d --extract '${toSopsPath(path)}' -d /dev/stdin`

export const buildNixExpression =
  (file: string, attribute: string, extraArgs: string = '') =>
    (secrets: Secrets) =>
      [
        `nix-build ${file} -A ${attribute} ${extraArgs}`,
        ...copyResultDerivationToS3('./result')(secrets)
      ]

export const runShellCommand =
  (command: string, attribute: string, extraArgs: string = '') =>
    (secrets: Secrets) =>
      [
        // would be fancier with pushd popd
        `cd /src/pipeline`,
        `nix-shell --run ${command} ${extraArgs}`,
        ...copyShellDependenciesToS3(secrets),
        `cd /`
      ]

export const copyShellDependenciesToS3 =
  ({ cacheBucket, awsRegion }: Secrets) =>
    [
      `nix-store --repair --verify`, // need to check how to skip this step
      `nix copy \
          --to ${bucketURL({ cacheBucket, awsRegion })}\
          $(nix-store -qR --include-outputs $(nix-instantiate shell.nix --add-root ./result --indirect))`,
      `nix path-info -r --json ./result | jq .`,
    ]

export const copyResultDerivationToS3 =
  (result: string = './result') =>
    ({ cacheBucket, awsRegion }: Secrets) =>
      [
        `nix-store --repair --verify`, // need to check how to skip this step
        `nix copy \
          --to ${bucketURL({ cacheBucket, awsRegion })}\
          $(nix-store --query --requisites --include-outputs $(nix-store --query --deriver ${result}))`,
        `nix path-info -r --json ./result | jq .`,
      ]

type Tasks = (string | ((secrets: WorkerSecrets) => string[]))[]

// investigate: https://github.com/brigadecore/brigade/blob/master/brigade-worker/src/k8s.ts#L886

export const AWS_ACCESS_KEY_ID = {
  secretKeyRef: {
    name: "aws-credentials",
    key: "access_key"
  }
}

export const AWS_SECRET_ACCESS_KEY = {
  secretKeyRef: {
    name: "aws-credentials",
    key: "secret_key"
  }
}

export class NixJob extends Job {

  secrets: Secrets
  event: BrigadeEvent
  extraParams: Partial<Job>
  _tasks: Tasks

  withSecrets(secrets: Secrets) {
    this.secrets = secrets as Secrets
    this.image = this.image ? this.image : this.secrets.workerDockerImage
    return this
  }

  withExtraParams(params: Partial<Job>) {
    this.extraParams = params
    return this
  }

  withTasks(tasks: Tasks) {
    this._tasks = tasks
    return this
  }

  withEnvVars(envVars: Record<string, string>) {
    this.env = envVars;
    return this
  }

  run(): Promise<Result> {
    const { cacheBucket, awsRegion } = this.secrets

    this.env = this.getEnvVars() as any as Job['env']

    this.tasks = [
      ...applyNixConfig({ cacheBucket, awsRegion }),
      // `cd /src`,
      // `./src/nix/run-tests.sh`, // running nix tests
      // not sure from \n comes from - check secret generation
      `AWS_ACCESS_KEY_ID="$(echo $AWS_ACCESS_KEY_ID | tr -d "\n")"`,
      `AWS_SECRET_ACCESS_KEY=$(echo $AWS_SECRET_ACCESS_KEY | tr -d "\n")`,
      ...this.resolveTasks(this.secrets)
    ]

    // this.cache.enabled = true
    // this.storage.enabled = true
    this.docker.enabled = true

    this.applyExtraParams()
    return super.run.apply(this)
  }

  private applyExtraParams() {
    Object
      .keys(this.extraParams)
      .forEach(param => {
        if (this[param]) this[param] = { ...this[param], ...this.extraParams[param] }
        this[param] = this.extraParams[param]
      })
  }

  private resolveTasks(secrets: Secrets) {
    return this._tasks
      .map(t => typeof t == 'function' ? t(secrets) : t)
      .reduce((acc, val) =>
        typeof val == "string"
          ? [...acc, val]
          : [...acc, ...val]
        , []) as string[]
  }

  private getEnvVars() {
    const { awsRegion, sopsSecrets } = this.secrets

    return {
      AWS_ACCESS_KEY_ID,
      AWS_SECRET_ACCESS_KEY,
      AWS_DEFAULT_REGION: awsRegion,
      SECRETS: sopsSecrets,
      ...this.env,
    }
  }
}