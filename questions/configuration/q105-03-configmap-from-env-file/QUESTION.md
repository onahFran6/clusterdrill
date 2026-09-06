# q105-03: Build a ConfigMap from an env file

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-03-configmap-from-env-file`

`setup.sh` already wrote a file to `$HOME/practice-work/q105-03-configmap-from-env-file/q105-03.env`
(this question's terminal working directory - shown above the terminal panel) containing:

```
LOG_LEVEL=debug
MAX_CONNECTIONS=50
```

Create a ConfigMap named `worker-settings` in namespace `q105-03-configmap-from-env-file` **from
that env file**, so each line becomes its own top-level data key (`LOG_LEVEL` and
`MAX_CONNECTIONS`) rather than the whole file being stored under one key. Do not create the keys
individually with `--from-literal`.

## Hint

Search kubernetes.io/docs for **"configmap from-env-file"** - the `kubectl create configmap`
command reference explains the difference between `--from-file` and `--from-env-file`.
