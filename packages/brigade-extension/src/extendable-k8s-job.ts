// I have to do here some magic to enable runtime transpilation
// @ts-ignore
const { events, Job, Group } = require("brigadier")
// @ts-ignore
const { JobRunner } = require("brigadier/../k8s") // because they are doing runtime path rewriting

// TODO add integration with sops
// TODO add task related to uploading the cache

// dark magic involved
// most likely all these problems are related to nix and mounted PV with noexec option ... need to read more about it
export class MyJob extends Job {
  // name: string;
  currentEvent: string
  currentProject: string
  jr: typeof JobRunner;

  with(currentEvent, currentProject) {
    this.currentEvent = currentEvent
    this.currentProject = currentProject
    return this
  }

  run() {
    // @ts-ignore
    this.jr = new JobRunner().init(this, currentEvent, currentProject, process.env.BRIGADE_SECRET_KEY_REF == 'true');
    // @ts-ignore
    this._podName = this.jr.name;

    this.jr.runner.spec.volumes.push({
      name: "global-build-storage",
      persistentVolumeClaim: {
        namespace: "brigade",
        claimName: "embracing-nix-docker-k8s-helm-knative-test"
      }
    })

    this.jr.runner.spec.containers[0].volumeMounts.push(
      { name: "global-build-storage", mountPath: "/global" } // as kubernetes.V1VolumeMount
    );

    return this.jr.run().catch(err => {
      // Wrap the message to give clear context.
      console.error(err);

      // @ts-ignore
      let msg = `job ${this.name}(${this.jr.name}): ${err}`;
      return Promise.reject(new Error(msg));
    });
  }
}