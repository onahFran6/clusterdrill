# q113-07: A Service with hand-made endpoints

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q113-07-handmade-endpoints`

Team Antares has a legacy server with a fixed IP and no DNS name of its own - in practice, Pod
`legacy` in this namespace. Their apps must be able to reach it as `legacy-svc:80`.

- Create Service `legacy-svc` (port 80, port name `http`) **without a selector**, and give it an
  EndpointSlice pointing at the legacy pod's IP on port 80.
- (ungraded, Task narrative only) Find the legacy pod's current IP yourself first
  (`kubectl get pod legacy -o jsonpath='{.status.podIP}'`) - without a selector, nothing
  auto-creates endpoints for you.

## Hint

Search kubernetes.io/docs for **"Services without selectors"** - the Service concept page's
section on it shows that a selector-less Service needs you to supply its own EndpointSlice,
labeled with `kubernetes.io/service-name` naming the Service, and that EndpointSlice's own port
`name` must match the Service's port `name`.
