# q112-14: A Pod that knows itself

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q112-14-downward-api-pod-knows-itself`

A metrics agent needs facts about its own Pod without ever calling the API server.

- Create Pod `meta` (`busybox:1.36`, `sleep 3600`, container named `agent`), labels `app=meta` and
  `version=v3`, annotation `build="4521"` (quote it - annotation values must be strings), and a
  memory limit of **64Mi**.
- Env var `POD_IP` holds the Pod's own IP. `MEM_LIMIT_MI` holds the container's memory limit in
  mebibytes, as a plain number.
- The Pod's labels and annotations must also appear as files: `/etc/podinfo/labels` and
  `/etc/podinfo/annotations`.

## Hint

Search kubernetes.io/docs for **"Expose Pod Information to Containers Through Environment
Variables"** and **"Expose Pod Information to Containers Through Files"**. Pod fields come
through `fieldRef`, and container resources come through `resourceFieldRef`. Which field of
`resourceFieldRef` turns raw bytes into "a plain number of Mi"? Labels and annotations are only
available as volume files, never as a single env var each.
