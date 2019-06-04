import { Job } from '@brigadecore/brigadier'
// IMPORTANT: from here we can take only types since brigade is doing runtime override
// I have to suggest them to use runInVm and pass the context rather than overriding runtime ...
import { Project, BrigadeEvent } from '@brigadecore/brigadier/out/events'
import { Result } from '@brigadecore/brigadier/out/job'

type WorkerSecrets = {
  workerDockerImage: string
  awsAccessKey: string
  awsSecretKey: string
  awsRegion: string
  cacheBucket: string
  sopsSecrets: {
    docker: {
      user: string
      apss: string
    }
  }
}

type NixProject = Project & { secrets: WorkerSecrets }
type Secrets = WorkerSecrets & Record<string, string>

export const bucketURL = ({ cacheBucket, awsRegion }) =>
  `s3://${cacheBucket}?region=${awsRegion}`

const applyNixConfig = ({ cacheBucket, awsRegion }) => [
  `echo "require-sigs = false" >> /etc/nix/nix.conf`,
  `echo "binary-caches = ${bucketURL({ cacheBucket, awsRegion })} https://cache.nixos.org/" >> /etc/nix/nix.conf`
]

export const saveSecrets = (fileName: string = 'secrets-encrypted.json') => [
  `echo $SECRETS | sops  --input-type json --output-type json -d /dev/stdin > ${fileName}`
]

export const buildNixExpression =
  (file: string, attribute: string, extraArgs: string = '') =>
    (secrets: Secrets) =>
      [
        `nix-build ${file} -A ${attribute} ${extraArgs}`,
        ...copyToCache('./result')(secrets)
      ]

export const copyToCache =
  (result: string = './result') =>
    ({ cacheBucket, awsRegion }: Secrets) =>
      [
        `nix-store --repair --verify`,
        `nix copy \
          --to ${bucketURL({ cacheBucket, awsRegion })}\
          $(nix-store --query --requisites --include-outputs $(nix-store --query --deriver ${result}))`,
      ]

type Tasks = (string | ((secrets: WorkerSecrets) => string[]))[]

export class NixJob extends Job {
  job: Job
  secrets: Secrets
  env: Job['env']
  image: string

  project: NixProject
  event: BrigadeEvent
  extraParams: Partial<Job>
  _tasks: Tasks

  constructor(name: string) {
    super(name)
  }

  withProject(project: Project) {
    this.project = project as NixProject
    this.secrets = project.secrets as Secrets
    this.image = this.secrets.workerDockerImage
    this.job = new Job(this.name, this.image)
    return this
  }

  withEvent(event: BrigadeEvent) {
    this.event = event
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

    this.job.env = {
      ...this.createDefaultEnvVars(),
      ...this.env
    }

    this.job.tasks = [
      ...applyNixConfig({ cacheBucket, awsRegion }),
      ...this.resolveTasks(this.secrets)
    ]

    this.applyExtraParams()
    return this.job.run()
  }

  logs(): Promise<string> {
    return this.job.logs()
  }

  private applyExtraParams() {
    Object
      .keys(this.extraParams)
      .forEach(param => {
        this.job[param] = this.extraParams[param]
      })
  }

  private resolveTasks(secrets: Secrets) {
    return this._tasks
      .map(t => typeof t == 'function' ? t(secrets) : t)
      .reduce((acc, val) => [...acc, ...val], []) as string[]
  }

  private createDefaultEnvVars() {
    const { awsAccessKey, awsSecretKey, awsRegion, secrets } = this.secrets

    return {
      AWS_ACCESS_KEY_ID: awsAccessKey,
      AWS_SECRET_ACCESS_KEY: awsSecretKey,
      AWS_DEFAULT_REGION: awsRegion,
      SECRETS: secrets,
    }
  }
}