# q102-17: Init container ConfigMap gate

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-17-init-container-configmap-gate`

This namespace is otherwise empty - create everything from scratch.

1. Create a ConfigMap named `app-config` with a single key `APP_MODE` set to
   the value `production`.
2. Create a Pod named `configmap-gated-app` with:
   - An init container named `wait-for-config` (image `busybox:1.36`) that
     represents a pre-flight check - it can simply run
     `sh -c "echo config check ok"` and exit successfully.
   - A main container named `main` (image `busybox:1.36`) that runs
     `sh -c "sleep 3600"` and consumes `app-config` as environment variables
     using `envFrom` with a `configMapRef` naming `app-config`, so `APP_MODE`
     becomes an environment variable inside the container.

## Hint

Search kubernetes.io/docs for **"define container environment variables using configmap data"**
- the ConfigMap task page shows the `envFrom` / `configMapRef` pattern this
task is based on.
