# q101-34: Productionize a running Pod as a scheduled CronJob

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-34-extract-pod-spec-into-cronjob`

An ops engineer manually ran a one-off Pod named `legacy-report-gen` in namespace
`q101-34-extract-pod-spec-into-cronjob` to test a report-generation container image. It is still
running. Nobody wrote down what image, environment variables, or command it uses - the engineer
just wants it turned into a proper scheduled job now that it's known to work.

Without eyeballing the raw pod YAML, use `kubectl get pod legacy-report-gen -o jsonpath=...` to
extract:

- the container's exact image
- every environment variable defined on the container (names and values)
- the container's exact command

Then create a CronJob named `report-job` that reproduces that same image, the same environment
variables (same names and same values), and the same command, running on the schedule
`*/5 * * * *`. Use `kubectl create cronjob ... --dry-run=client -o yaml` to generate a starting
manifest, edit in the extracted environment variables and command, then apply it - do not
hand-write the CronJob manifest from scratch.

When you are done, `report-job`'s pod template must launch a container that behaves exactly like
`legacy-report-gen` currently does, just on a recurring schedule instead of as a one-off Pod.

## Hint

Search kubernetes.io/docs for **"kubectl create cronjob"** - the command reference page shows the
`--dry-run=client -o yaml` pattern for generating an editable starting manifest before you `apply`
it.
