# q111-02: Probes described by behaviour

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q111-02-probes-by-behaviour`

Team Minerva's `catalog` Deployment (seeded, 3 replicas, `nginx:1.27`) receives traffic before
nginx is ready, and hung containers are never restarted. Add health checks to its container:

- A pod only receives Service traffic once an HTTP request to path `/` on port **80** succeeds.
  Check every **5** seconds, starting **5** seconds after the container starts.
- If port 80 stops accepting TCP connections for about **30** seconds, restart the container.
  Check every **10** seconds.
- Confirm the readiness probe you wrote matches by reading it back off the Deployment.

## Hint

Search kubernetes.io/docs for **"Configure Liveness, Readiness and Startup Probes"**. Which
probe controls Service traffic, and which one restarts containers? "About 30 seconds at one
check every 10 seconds" is a number of consecutive failures, and one probe field holds it.
There's no `kubectl set probe`, so the change has to go through a patch or a full manifest
replace.
