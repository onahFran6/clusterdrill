# q113-05: Headless - see every pod

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q113-05-headless-see-every-pod`

Team Deneb's client library wants to discover every `cache` pod itself instead of going through a
single load-balanced IP. Deployment `cache` (3 replicas) and a normal Service `cache-svc` already
exist.

- Create Service `cache-headless` for the same pods, with no cluster IP.

## Hint

Search kubernetes.io/docs for **"headless services"** - the Service concept page's Headless
Services section covers the one `spec` field, set to a special value, that removes a Service's
cluster IP. `kubectl expose -h` has a flag for it. Predict how many addresses a DNS lookup against
each Service should return before you check.
