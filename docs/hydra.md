### Hydra instance

Whole state is in `s3` so there is no need to run `hydra` all the time.
possible scenarios: schedule to do a chanel invalidation
integrate with hooks from knative eventing

### Issues
* (WIP - added script on reload - most likely postgress does not keep storage) when bootstraping with terraform there is a need to do apply 2x - not sure yet - if not, hydra will be running ok, however there won't be predefined project
* sometimes there is a huge lag to get `hydra` ui - not sure why yet (solved - dns issue)
* backup/restore postgres (not super important - `s3` cache is important)