# q118-06: Migrate with configuration and credentials

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q118-06-migration-with-config-and-secret`

Team Neptune stores migration settings in *ConfigMap* `migrate-config` and credentials in *Secret* `db-creds`.
Create *Job* `migrate` using `busybox:1.36`, importing every ConfigMap key as an environment variable and only Secret key `password` as `DB_PASSWORD`.
Run `sh -c 'echo migrating $DB_HOST to v$TARGET_VERSION; [ -n "$DB_PASSWORD" ] && echo password present'`.
Neither the kubelet nor the Job controller may retry a failed migration.
Confirm completion and read the log without exposing the password.

## Hint

Search kubernetes.io/docs for "envFrom ConfigMap", "secretKeyRef", and "Job backoff limit".
