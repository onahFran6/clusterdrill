# q101-18: Annotate an existing resource

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-18-annotate-resource`

`setup.sh` already created a Deployment named `billing-api` in namespace
`q101-18-annotate-resource`.

Using a single imperative `kubectl annotate` command, add the annotation
`owner-team=billing-platform` to the `billing-api` Deployment, without touching any of its other
fields.

## Hint

Search kubernetes.io/docs for **"kubectl annotate"** - the `kubectl annotate` command reference
shows how to attach metadata annotations to an existing object in place.
