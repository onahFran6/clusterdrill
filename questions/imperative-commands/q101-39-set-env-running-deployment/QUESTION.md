# q101-39-set-env-running-deployment: Add an environment variable to a running Deployment

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-39-set-env-running-deployment`

`setup.sh` already created a Deployment named `report-worker` (image `busybox:1.36`, running
`sleep 3600`) in namespace `q101-39-set-env-running-deployment`.

Without editing a manifest by hand, add an environment variable `FEATURE_FLAG=beta` to its
container using a single imperative `kubectl set env` command, and let the rollout finish so the
new pod actually carries the variable.

## Hint

Search kubernetes.io/docs for **"kubectl set env"** - the kubectl reference documents
`kubectl set env deployment/<name> KEY=VALUE` for updating a container's environment variables
without hand-editing YAML.
