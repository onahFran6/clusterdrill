# q105-20: Give a pod the Guaranteed QoS class

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-20-guaranteed-qos-class`

`setup.sh` already created a running pod named `critical-job` (image `nginx:1.25-alpine`) in
namespace `q105-20-guaranteed-qos-class`, with a CPU request of `200m` and a higher CPU limit of
`500m` - a `Burstable` pod today.

Edit the pod's single container's resources so the pod is scheduled into the **`Guaranteed`**
Quality of Service class instead: every resource type the container requests must have an equal
request and limit (set both CPU and memory to request **and** limit `300m` CPU / `256Mi` memory).
The pod will need to be recreated for the change to take effect.

## Hint

Search kubernetes.io/docs for **"pod quality of service classes"** - the Pod Quality of Service
Classes concept page defines exactly what "Guaranteed" requires: every container needs both a
memory and a CPU limit, and each container's request must equal its limit for every resource.
