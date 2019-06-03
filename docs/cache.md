## For local development
* TODO there will be separate bucket for local builds on `s3` as project is growing and require lots of dependencies

## For CI
### Brigade handle it via PVC
https://docs.brigade.sh/topics/javascript/

https://github.com/brandon-bethke-neudesic/brigade/blob/cef43b38fad83975da817245f6bc6167e90dea42/brigade-worker/src/k8s.ts#L43

 •  kubernetes.cacheStorageClass: This is used for the Job cache.
 •  kubernetes.buildStorageClass: This is used for the shared per-build storage.


Idea is that: 
* each build is doing rsync to cache/build storage -- there is no way to do this without endpoint for upload since there is no shared space between workers - need to write custom worker with embeded pvc - easy ...
* storage is mounted to remote-worker
* remote-work act as remote-binary-store

above is too tricky, possible but tricky, better is to go with s3, in case of azure, minio will provide interface for s3 like api
