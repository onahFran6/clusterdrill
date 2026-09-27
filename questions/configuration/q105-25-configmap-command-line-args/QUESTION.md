# q105-25: Feed ConfigMap values into a container's command arguments

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-25-configmap-command-line-args`

A ConfigMap named `greeter-config` already exists with keys `GREETING=Hello` and `TARGET=World`,
plus a Pod named `greeter` whose container just sleeps and never references either key, so
`kubectl logs greeter` is currently empty, in namespace `q105-25-configmap-command-line-args`.

Edit the pod so its container:

- gets two environment variables, `GREETING` and `TARGET`, sourced from the matching keys of
  `greeter-config`, and
- runs a shell command that uses `$(GREETING)` and `$(TARGET)` command-line argument
  substitution to print the literal line `Hello World` to stdout, then keeps running (for
  example, sleep afterwards) so the pod stays `Running`.

Verify with `kubectl logs greeter` - it should show `Hello World`.

## Hint

Search kubernetes.io/docs for **"define dependent environment variables"** - the Define
Environment Variables for a Container task covers referencing ConfigMap keys as env vars and
using `$(VAR)` substitution in a container's `command`/`args`.
