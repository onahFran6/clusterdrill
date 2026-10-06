# q116-14: A range of ports

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q116-14-a-range-of-ports`

Pod `game` (label `app: game`) opens session ports anywhere from `7000` to `7100`. Pod `player`
(label `role: player`) already exists.

- Create NetworkPolicy `game-ports` for `game`, using a **single** port entry, covering TCP
  `7000`-`7100`, allowed from `role: player` only.
- (ungraded, Task narrative only) From `player`, record TCP connect results to `game` on port
  `7050` and on port `7200`.

## Hint

Search kubernetes.io/docs for **"NetworkPolicy"** and check `kubectl explain
networkpolicy.spec.ingress.ports` - one field turns a plain `port` into the start of a range.
