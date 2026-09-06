# q106-09: Check your own permissions with `kubectl auth can-i`

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-09-auth-can-i-self`

Before filing a ticket asking for more access, you want to confirm exactly what your current
`kubectl` identity can and cannot do in namespace `q106-09-auth-can-i-self`.

Using `kubectl auth can-i`, determine whether your current identity can `create` `deployments` in
this namespace, then record the literal answer (`yes` or `no`) as the value of key `answer` in a
ConfigMap named `can-i-result` in this namespace.

## Hint

Search kubernetes.io/docs for **"kubectl auth can-i"** - the `kubectl` reference book shows the
exact command form for checking a verb/resource combination against the current user.
