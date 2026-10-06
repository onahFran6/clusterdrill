# q112-10: A slow starter that keeps getting killed

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q112-10-slow-starter-probes`

This app takes about **20 seconds** to boot. When it is up, it creates `/tmp/started`,
`/tmp/healthy` and `/tmp/ready`. A naive liveness check would kill it before it finishes booting.

- Create Pod `slowboot` (`busybox:1.36`) running
  `sleep 20; touch /tmp/started /tmp/healthy /tmp/ready; sleep 3600`.
- Allow up to **60 seconds** for boot: an `exec` probe checking `cat /tmp/started` every **2**
  seconds, with enough failures tolerated to cover the full 60 seconds.
- After boot, restart the container if `/tmp/healthy` disappears (`exec cat /tmp/healthy`, check
  every **5** seconds).
- Only count the Pod Ready while `/tmp/ready` exists (`exec cat /tmp/ready`, check every **3**
  seconds).
- **After the Pod reaches Ready, delete `/tmp/ready` from inside the container yourself** - this
  is the task's own final step, not just a way to verify your probes.

## Hint

Search kubernetes.io/docs for **"Configure Liveness, Readiness and Startup Probes"**. Which probe
exists specifically so slow starters do not need a huge liveness delay? 60 seconds at one check
every 2 seconds is a `failureThreshold` value. All three checks are file tests, so use `exec`
probes. Before you remove `/tmp/ready`, predict the result: does a failing readiness probe ever
restart a container?
