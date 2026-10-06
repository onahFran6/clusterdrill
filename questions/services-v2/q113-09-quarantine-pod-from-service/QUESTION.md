# q113-09: Take a pod out of rotation

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q113-09-quarantine-pod-from-service`

Team Spica's `menu` Deployment (3 replicas) sits behind Service `menu-svc`. One pod is
misbehaving and they want to investigate it live, without losing it.

- Pick any one `menu` pod. Remove it from `menu-svc` **and** from its Deployment's control,
  without deleting it, so `menu-svc` still has 3 serving pods and the ReplicaSet replaces the one
  you picked.

## Hint

Search kubernetes.io/docs for **"ReplicaSet" "how a ReplicaSet works"** - both the Service and the
ReplicaSet find their pods purely by label selector. Change one label on the chosen pod and work
through what each controller does next: will the ReplicaSet still count it? Will the Service?
