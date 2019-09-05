### Reads
* https://rook.io/
* https://blog.mellanox.com/2016/10/ceph-for-databases-yes-you-can-and-should/
* https://earlruby.org/2018/12/using-rook-ceph-for-persistent-storage-on-kubernetes/
* https://blog.kubernauts.io/backup-and-restore-of-kubernetes-applications-using-heptios-velero-with-restic-and-rook-ceph-as-2e8df15b1487

### Watch
* https://www.youtube.com/watch?v=h38FCAuOehc

### schedules 
* https://github.com/heptio/velero/pull/1473/files

### `rook ceph`, `restic` and `velero`
* https://velero.io/docs/v1.1.0/restic/

### checking `velero`schedules
* `velero schedule get`

### checking `restic` repository
* `velero restic repo get`

### Performance
* https://medium.com/vescloud/kubernetes-storage-performance-comparison-9e993cb27271

### using `restic` cli
* `restic check -r s3:s3.amazonaws.com/future-is-comming-dev-backup/restic/ci`

### some other cli combination
* velero restore create --include-namespaces=gitlab --include-resources persistentvolumeclaims,persistentvolumes --from-backup=velero-daily-20190827164509 --restore-volumes

### restoring content to local folder
* `velero backup create ci-6 --include-namespaces ci --wait`
* `restic snapshots -r s3:s3.amazonaws.com/future-is-comming-dev-backup/restic/ci`
* `restic restore f3c5db07 --target ./temp/test-recovery -r s3:s3.amazonaws.com/future-is-comming-dev-backup/restic/ci`