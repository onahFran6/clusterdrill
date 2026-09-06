# q107-37: Extract a custom field report from a set of pods

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-37-custom-columns-extraction`

`setup.sh` already created three Pods in this namespace: `fleet-alpha` (`nginx:1.24-alpine`),
`fleet-beta` (`nginx:1.25-alpine`), and `fleet-gamma` (`busybox:1.36`). Using a single
`kubectl get pods` command with `-o custom-columns` (not `-o json`/`jsonpath` piped through another
tool), produce a two-column report of each pod's name and container image with no header row, and
redirect it into a file at `$HOME/practice-work/q107-37-custom-columns-extraction/fleet-images.txt`
on the terminal host.

## Hint

Search kubernetes.io/docs for **"custom columns"** - the kubectl reference's output-formatting
section shows `-o custom-columns=<HEADER>:<jsonpath>,...` for building an ad-hoc tabular report
directly from `kubectl get`, and `--no-headers` for dropping the column header row.
