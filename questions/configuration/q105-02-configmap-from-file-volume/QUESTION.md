# q105-02: Build a ConfigMap from a file and mount it as a volume

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-02-configmap-from-file-volume`

`setup.sh` already created a file at `$HOME/practice-work/q105-02-configmap-from-file-volume/q105-02-nginx.conf`
(this question's terminal working directory - shown above the terminal panel), and a running pod
named `web-server` (image `nginx:1.25-alpine`) in namespace `q105-02-configmap-from-file-volume`.

Create a ConfigMap named `nginx-conf` whose data comes from the **contents of that file** (the
key must end up being the file's base name, `q105-02-nginx.conf`) - do not retype the file's
contents as a literal.

Then edit the pod so the container mounts `nginx-conf` as a volume at `/etc/nginx/conf.d`,
making the file available inside the container at `/etc/nginx/conf.d/q105-02-nginx.conf`. The
pod will need to be recreated for the mount to take effect.

## Hint

Search kubernetes.io/docs for **"configmap from-file"** - the Configure a Pod to Use a ConfigMap
task covers creating a ConfigMap from a file and mounting the whole ConfigMap as a volume.
