# q102-03: Ambassador proxy container

**Domain:** Application Design and Build · **Points:** 7 · **Namespace:** `q102-03-ambassador-proxy-port`

Create a Pod named `app-with-ambassador` with two containers:

- `app` (image `busybox:1.36`) - simulates an application that only knows
  how to talk to a database on `localhost`. Give it a command that loops
  forever, on each iteration attempting to reach `localhost:6380` (for
  example with `wget` or by just referencing that address in a sleep loop).
- `ambassador` (image `alpine:3.20`) - the ambassador/proxy container that
  listens on local port `6380` and forwards traffic to an external service
  `redis-external` on port `6379`, using `socat` (for example:
  `socat TCP-LISTEN:6380,fork TCP:redis-external:6379`).

This is the ambassador pattern: the `app` container is only ever configured
to talk to `localhost`, and the `ambassador` container sitting next to it in
the same Pod handles proxying to the real, possibly-remote backend.

## Hint

Search kubernetes.io/docs for **"multi-container pods communicate"** - the
Pods concept page's "Communication between containers in the same Pod"
section describes the ambassador container pattern this task is based on.
