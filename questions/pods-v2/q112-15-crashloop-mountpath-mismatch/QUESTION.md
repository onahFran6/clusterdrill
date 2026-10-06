# q112-15: CrashLoopBackOff with a config file

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q112-15-crashloop-mountpath-mismatch`

Pod `calc` (seeded) has restarted dozens of times. Its command
(`cat /config/app.conf && sleep 3600`) and ConfigMap `app-conf` are both correct and must not
change.

- `(ungraded)` Before fixing anything, find the exit code of the last failed run
  (`lastState.terminated.exitCode`) and the exact error line it printed
  (`kubectl logs --previous`).
- Fix `calc` so it stays Running, keeping its name. The ConfigMap and the container's command must
  not change.

## Hint

Search kubernetes.io/docs for **"CrashLoopBackOff"** and **"Debug Running Pods"**. The current
container may still be in back-off, so ask for the logs of the *previous* one with
`kubectl logs --previous`. The exit code lives under `lastState` in the container status. Compare
the path the command actually reads with the path the ConfigMap volume is mounted on.
