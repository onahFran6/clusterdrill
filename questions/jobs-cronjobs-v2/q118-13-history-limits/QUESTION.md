# q118-13: Keep a small recent run history

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q118-13-history-limits`

Team Titan has *CronJob* `ping` filling its namespace with old runs.
Keep only the latest **2** successful Jobs and **1** failed Job, without changing the image, command, or every-minute schedule.
Wait about four minutes and confirm two completed successful runs remain.
An active run may briefly coexist with them.

## Hint

Search kubernetes.io/docs for "CronJob Jobs history limits" and which Jobs count toward each limit.
