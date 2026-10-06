# q113-10: Sticky canary

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q113-10-sticky-canary-session-affinity`

Team Arcturus runs `whoami-stable` (4 replicas) and `whoami-canary` (1 replica) behind Service
`whoami`; each pod replies with its own hostname. Users complain that pages flip between versions
mid-session.

- Change `whoami` so a given client keeps reaching the same pod for up to **10 minutes**, while
  new clients are still spread roughly 80/20 across the two versions.

## Hint

Search kubernetes.io/docs for **"Service" "session affinity"** - the Service concept page's
Session affinity section has a field for stickiness by client IP, and a nested config for its
timeout. Check how many endpoints `whoami` has before you touch anything, to confirm which shared
pod label makes the 80/20 split work in the first place.
