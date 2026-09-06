# q102-16: Adapter metrics exporter

**Domain:** Application Design and Build · **Points:** 7 · **Namespace:** `q102-16-adapter-metrics-exporter`

A Pod named `metrics-app` already exists in this namespace with a single
container named `app` (image `busybox:1.36`) that continuously writes a raw,
custom-format metrics line like `requests_total:42` to `/metrics/raw.txt`.
The volume backing `/metrics` is an `emptyDir` named `metrics-vol`.

You cannot add a container to a running pod in place, so delete and recreate
the `metrics-app` pod, keeping the existing `app` container's image, volume,
and command unchanged, and add a second container named `metrics-adapter`
(image `busybox:1.36`) that:

- Mounts the **same** `metrics-vol` volume at `/metrics`.
- Runs a loop that reads `/metrics/raw.txt`, transforms each
  `metric_name:value` line into Prometheus text format (`metric_name value`,
  space-separated instead of colon-separated - for example with
  `sed 's/:/ /'`), and appends the result to `/metrics/prometheus.txt`.

This is the "adapter" multi-container pattern: a second container transforms
one container's output into a format a different consumer (e.g. a
Prometheus scraper) expects, without changing the original container.

The pod must end up with exactly two containers: `app` and
`metrics-adapter`.

## Hint

Search kubernetes.io/docs for **"multi-container pods communicate"** - the
Pods concept page's "Communication between containers in the same Pod"
section covers the adapter container pattern this task is based on.
