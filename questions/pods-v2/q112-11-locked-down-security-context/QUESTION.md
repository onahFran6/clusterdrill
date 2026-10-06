# q112-11: A locked-down Pod that can still write

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q112-11-locked-down-security-context`

A security review requires the following for Pod `locked` (`busybox:1.36`, running `sleep 3600`):

- All processes run as user **1000** and group **3000**. Files on mounted volumes belong to group
  **2000**.
- The container's root filesystem is read-only, it cannot escalate privileges, and it drops
  **all** Linux capabilities.
- The app must still be able to write to `/data`.

## Hint

Search kubernetes.io/docs for **"Configure a Security Context for a Pod or Container"**. Sort the
fields first: which belong to the **Pod-level** `securityContext`, and which exist only at the
**container** level? A read-only root filesystem needs somewhere writable, so which volume type
gives you exactly that?
