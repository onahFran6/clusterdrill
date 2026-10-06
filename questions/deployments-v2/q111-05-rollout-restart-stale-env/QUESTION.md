# q111-05: ConfigMap changed, pods didn't

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q111-05-rollout-restart-stale-env`

Team Diana changed `GREETING` in ConfigMap `web-config` from `hello` to `hola` (already changed
by the time you look). The `greeter` Deployment loads it as an env var, but its running pods
still report the old value.

- Make every `greeter` pod use the new value, without downtime and without hand-editing the
  Deployment's spec.
- Be able to explain in one line why the pods didn't pick up the change on their own.

## Hint

Search kubernetes.io/docs for **"Understanding ConfigMaps and Pods"**. When does a container
actually read its env vars - once, or continuously? Changing a ConfigMap does not change a
Deployment's pod template, so nothing about the live pods should change on its own. One `rollout`
subcommand replaces every pod through the normal rolling strategy, without you editing anything.
