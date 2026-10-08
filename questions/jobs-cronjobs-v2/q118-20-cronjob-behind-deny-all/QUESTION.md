# q118-20: Let only the scheduled reporter reach its backend

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q118-20-cronjob-behind-deny-all`

Team Oberon has *Pods* `report` and `other`, *Service* `report-svc` on TCP **8080**, and *CronJob* `reporter` behind a `deny-all` *NetworkPolicy*.
Label the CronJob Pods `app=reporter`.
Create *NetworkPolicies* `reporter-egress` and `report-from-reporter` allowing only reporter egress to `app=report` on TCP 8080, report ingress from `app=reporter` on TCP 8080, and reporter DNS egress to CoreDNS on UDP/TCP 53.
For DNS use namespace label `kubernetes.io/metadata.name=kube-system` together with Pod label `k8s-app=kube-dns`.
Keep `deny-all`, the Service, and the reporter workload unchanged.
Trigger *Job* `reporter-now` and confirm its log is `report ok`.
On a policy-enforcing CNI, verify `other` remains blocked (practice observation, ungraded); policy grading checks configuration.

## Hint

Search kubernetes.io/docs for "NetworkPolicy ingress egress isolation" and how selectors within one peer combine.
