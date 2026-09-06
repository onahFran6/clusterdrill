# q105-25-configmap-command-line-args: Feed ConfigMap values into a container's command arguments

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-25-configmap-command-line-args`

`setup.sh` already created a ConfigMap named `greeter-config` with keys `GREETING=Hello` and
`TARGET=World`, plus a pod named `greeter` whose container just sleeps and never references
either key, so `kubectl logs greeter` is currently empty, in namespace
`q105-25-configmap-command-line-args`.

Edit the pod so its container:

- gets two environment variables, `GREETING` and `TARGET`, sourced from the matching keys of
  `greeter-config`, and
- runs a shell command that uses `$(GREETING)` and `$(TARGET)` command-line argument
  substitution to print the literal line `Hello World` to stdout, then keeps running (for
  example, sleep afterwards) so the pod stays `Running`.

Do not change the ConfigMap. The pod will need to be recreated for the change to take effect, and
`kubectl logs greeter` must contain the line `Hello World`.

## Hint

Search kubernetes.io/docs for **"define-environment-variables-for-a-container"** - the Define
Dependent Environment Variables task shows how `$(VAR_NAME)` in a container's `command`/`args`
expands from previously defined environment variables.
