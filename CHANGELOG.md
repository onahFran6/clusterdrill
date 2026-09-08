# Changelog

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
