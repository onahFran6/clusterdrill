# q112-12: Four Pods, four QoS predictions

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q112-12-four-pods-four-qos-predictions`

The kubelet evicts Pods in a strict order under memory pressure, driven entirely by each Pod's QoS
class. Create four `nginx:1.27` Pods in this namespace:

- `gold`, which must land in the **highest** QoS class - give it **100m** CPU and **64Mi** memory,
  with requests equal to limits.
- `silver`, which requests only **50m** CPU and declares nothing else.
- `bronze`, with no resources block at all.
- `tin`, with **limits only**: **100m** CPU and **64Mi** memory, no requests block.
- `(ungraded)` Before you check, predict `tin`'s QoS class.

## Hint

Search kubernetes.io/docs for **"Pod Quality of Service Classes"**. The top class needs requests
equal to limits, for both CPU and memory, on every container. When a container declares a limit
but no request, what does the API server fill in for the missing request?
