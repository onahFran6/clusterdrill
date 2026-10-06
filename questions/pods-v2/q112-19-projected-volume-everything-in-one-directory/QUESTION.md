# q112-19: Everything in one directory

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q112-19-projected-volume-everything-in-one-directory`

An app in this namespace reads all its inputs from one directory, `/etc/bundle`. ConfigMap
`app-cfg` (key `app.yaml`) and Secret `app-sec` (key `token`) are already seeded here.

- Create Pod `bundle` (`busybox:1.36`, `sleep 3600`, label `app=bundle`) where `/etc/bundle` holds,
  from a **single** volume:
  - `app.yaml` from ConfigMap `app-cfg`.
  - `secret/token` from the `token` key of Secret `app-sec`.
  - `meta/labels` with the Pod's own labels.
  - `vault-token`: a ServiceAccount token for audience `vault`, valid for **1 hour**.

## Hint

Search kubernetes.io/docs for **"Projected Volumes"**. One volume type merges several different
source types into a single directory. Each source takes its own `items` list (or, for a
ServiceAccount token, a `path` field directly), and paths may include subdirectories.
