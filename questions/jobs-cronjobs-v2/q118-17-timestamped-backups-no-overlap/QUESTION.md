# q118-17: Keep two timestamped research backups

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q118-17-timestamped-backups-no-overlap`

Team Phobos has *Deployment* `notes` writing to *PVC* `data`.
Create *PVC* `backups` (**200Mi**, default StorageClass, `ReadWriteOnce`) and *CronJob* `backup` using `busybox:1.36` every six hours.
Mount `data` read-only at `/data` and `backups` read-write at `/backups`, copying the source into a new `/backups/<YYYYmmdd-HHMMSS>/` directory per run.
Skip scheduled runs while an earlier backup is active.
Trigger Jobs `backup-1` and `backup-2`, at least a second apart, and leave exactly two timestamped directories containing `notes.log`.

## Hint

Search kubernetes.io/docs for "CronJob concurrency policy" and "persistentVolumeClaim readOnly"; inspect the claim from a separate reader Pod.
