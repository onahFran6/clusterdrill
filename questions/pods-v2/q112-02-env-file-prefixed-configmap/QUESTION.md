# q112-02: Env file into a prefixed ConfigMap

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q112-02-env-file-prefixed-configmap`

This namespace's shop settings live in `shop.env`, one `KEY=value` per line, already sitting in
your terminal's working directory - `cat shop.env` to see it.

- Create ConfigMap `shop-config` in which **each line** of that file becomes its own key.
- Create Pod `shop` (`nginx:1.27`) that receives every key from `shop-config` as an env var with
  the prefix `SHOP_` (for example `SHOP_THEME`).
- Verify the result: every env var starting with `SHOP_` must be visible inside the running Pod.

## Hint

Search kubernetes.io/docs for **"Define Environment Variables for a Container"** and
**"Configure all key-value pairs in a ConfigMap as container environment variables"**.
`kubectl create configmap` has two file flags - one makes the whole file a single key, and the
other reads it line by line. Check `kubectl get cm shop-config -o yaml` before moving on.
`envFrom` has a field that adds a prefix.
