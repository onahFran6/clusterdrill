# Changelog

## [0.1.7](https://github.com/onahFran6/clusterdrill/compare/v0.1.6...v0.1.7) (2026-09-24)


### Features

* **helm-crds:** add 9 Helm CLI drill questions (q110-52..q110-60) ([2499e27](https://github.com/onahFran6/clusterdrill/commit/2499e272d854a41acb6504877edc5f6c296ff880))
* **helm-crds:** add q110-51 named template label fix question ([d12365f](https://github.com/onahFran6/clusterdrill/commit/d12365f22ebd3fcef444faf6f1aa41051e629578))
* **helm-crds:** add q110-52 pinned chart version install question ([6fa5b82](https://github.com/onahFran6/clusterdrill/commit/6fa5b82fbe33162517b27c974a91a9832f84d430))
* **helm-crds:** add q110-53 nested set and set-string question ([3f97a5f](https://github.com/onahFran6/clusterdrill/commit/3f97a5f10df9a0f1ccc48ab28c0866612763235d))
* **helm-crds:** add q110-54 atomic upgrade rollback question ([5ba484f](https://github.com/onahFran6/clusterdrill/commit/5ba484f4ae71595008a846a0f496854c4f20a1aa))
* **helm-crds:** add q110-55 stuck pending-upgrade recovery question ([d213dcb](https://github.com/onahFran6/clusterdrill/commit/d213dcbeda2547efef90ee7ea62ec6e6a76c0516))
* **helm-crds:** add q110-56 cluster-wide failed release audit question ([f8090d4](https://github.com/onahFran6/clusterdrill/commit/f8090d46c3f4596fa2c8e2b4ec656fcf84128cb7))
* **helm-crds:** add q110-57 get values past revision question ([35b6aed](https://github.com/onahFran6/clusterdrill/commit/35b6aedf5593314df5388575dad9b751c2b3b8bc))
* **helm-crds:** add q110-58 helm template zero-contact question ([5048c91](https://github.com/onahFran6/clusterdrill/commit/5048c91c5cfeb2625364e716c0ee5559e39f8306))
* **helm-crds:** add q110-59 uninstall keep-history reinstate question ([9655911](https://github.com/onahFran6/clusterdrill/commit/9655911f310b8650e3d9f4b966d32635365b537b))
* **helm-crds:** add q110-60 values precedence three-way question ([d860091](https://github.com/onahFran6/clusterdrill/commit/d8600913290befebd45e869dbee740c49e3737a4))


### Bug Fixes

* **imperative-commands:** stop grading the wrong pod after a rollout ([0b5405c](https://github.com/onahFran6/clusterdrill/commit/0b5405c925a9b78b51bb9e57dd960b41bf904e8e))
* **lib:** raise default ResourceQuota memory to fit pods=12 ceiling ([753e9cf](https://github.com/onahFran6/clusterdrill/commit/753e9cf20e3ab93bd192f13ce3c5a08356c4a19e))
* **multi-container-pods:** grade actual data flow, not just readiness ([902c992](https://github.com/onahFran6/clusterdrill/commit/902c992dcc6a7f881813a78e87fedb72c06ac16a))
* **observability:** clean stale local output files in setup.sh ([aafc4fd](https://github.com/onahFran6/clusterdrill/commit/aafc4fd675def8aaf664f106119bbcef5f3bb993))

## [0.1.6](https://github.com/onahFran6/clusterdrill/compare/v0.1.5...v0.1.6) (2026-09-08)


### Features

* alias kubectl to k in the practice-work terminal ([fe10d37](https://github.com/onahFran6/clusterdrill/commit/fe10d37bc2f9071d76f40dedc45c98b20d9d2db7))


### Bug Fixes

* hide hint/diagram tabs and gate reset button during exams ([acac470](https://github.com/onahFran6/clusterdrill/commit/acac4700fb03cda55882d27611387a02ed0d844e))

## [0.1.5](https://github.com/onahFran6/clusterdrill/compare/v0.1.4...v0.1.5) (2026-09-08)


### Bug Fixes

* skip Helm smoke test gracefully when no digest exists yet for this version ([2626767](https://github.com/onahFran6/clusterdrill/commit/26267677c884d4299df2795bcfbe7a07d9fb863c))

## [0.1.4](https://github.com/onahFran6/clusterdrill/compare/v0.1.3...v0.1.4) (2026-09-08)


### Features

* validate digest before opening the manifest-update PR ([348e025](https://github.com/onahFran6/clusterdrill/commit/348e025d731c05a03143dc1f36e626626e50c867))

## [0.1.3](https://github.com/onahFran6/clusterdrill/compare/v0.1.2...v0.1.3) (2026-09-07)


### Features

* let release-image.yml be safely dry-run against non-release tags ([f0b10e7](https://github.com/onahFran6/clusterdrill/commit/f0b10e71427f4504a70e47646b809278e7a34c8a))


### Bug Fixes

* add --repo flag to release-image trigger call ([bc5ef06](https://github.com/onahFran6/clusterdrill/commit/bc5ef06181431709cccbc1ffb08e2173225b7ee6))
* exclude auto-generated CHANGELOG.md from markdownlint ([23a221b](https://github.com/onahFran6/clusterdrill/commit/23a221b944f6ac18e2b0cd4e6e0b6aa4bcb831d1))

## [0.1.2](https://github.com/onahFran6/clusterdrill/compare/v0.1.1...v0.1.2) (2026-09-07)


### Bug Fixes

* remove duplicate Changelog heading from bad seed file ([6b66041](https://github.com/onahFran6/clusterdrill/commit/6b6604184edd8a6ee328876e6eaf7b06cb37ec4f))
* trigger release-image via workflow_dispatch instead of tag push ([1462042](https://github.com/onahFran6/clusterdrill/commit/146204252660a22af3b351fbaaa07bcc459ed963))

## [0.1.1](https://github.com/onahFran6/clusterdrill/compare/v0.1.0...v0.1.1) (2026-09-07)

### Features

* add release-image workflow to build/push multi-arch image and OCI chart ([83d4b6c](https://github.com/onahFran6/clusterdrill/commit/83d4b6c97a3607c7c7173810343774a882676653))
* adopt release-please for versioning ([55ecc46](https://github.com/onahFran6/clusterdrill/commit/55ecc46928d4f02e544fb817e06c05f43688bc38))
