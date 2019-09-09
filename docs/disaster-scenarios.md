## disaster scenarios

### delete namespace
`velero restore create --from-schedule backup-velero-all-ns --include-namespaces <namespace> -n eks`

### before things which can leads to instability
`velero backup create current-state`