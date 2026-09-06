# q105-22: Create an ssh-auth typed Secret and mount it

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-22-secret-ssh-auth-type`

`setup.sh` already created a file at
`$HOME/practice-work/q105-22-secret-ssh-auth-type/id_rsa` (this question's terminal working
directory - shown above the terminal panel) containing a placeholder SSH private key, and a
running pod named `deploy-agent` (image `nginx:1.25-alpine`) in namespace
`q105-22-secret-ssh-auth-type`.

Create a Secret named `deploy-key` whose type is specifically `kubernetes.io/ssh-auth` (not the
generic `Opaque` type), with a single key `ssh-privatekey` whose value comes from that file's
**contents** (do not retype the key as a literal).

Then edit the pod so its container mounts `deploy-key` as a volume at `/etc/ssh-key`, making the
private key available inside the container at `/etc/ssh-key/ssh-privatekey`. The pod will need to
be recreated for the mount to take effect.

## Hint

Search kubernetes.io/docs for **"secret type ssh-auth"** - the Secrets concept page's "SSH
authentication secrets" section shows the required key name and the `--type` flag
`kubectl create secret generic` needs to produce this specific Secret type.
