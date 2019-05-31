### Brigade handle it via PVC
https://docs.brigade.sh/topics/javascript/

https://github.com/brandon-bethke-neudesic/brigade/blob/cef43b38fad83975da817245f6bc6167e90dea42/brigade-worker/src/k8s.ts#L43

Idea is that:
* each build is doing rsync to cache/build storage
* storage is mounted to remote-worker
* remote-work act as remote-binary-store
