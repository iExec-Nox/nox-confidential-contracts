# Changelog

## [0.2.0](https://github.com/iExec-Nox/nox-confidential-contracts/compare/v0.1.0...v0.2.0) (2026-04-21)


### ⚠ BREAKING CHANGES

* Make optimized contracts as the default for token and wrapper ([#29](https://github.com/iExec-Nox/nox-confidential-contracts/issues/29))
* Rename "advanced" and "basic" contracts to use "optimized" and "raw" ([#28](https://github.com/iExec-Nox/nox-confidential-contracts/issues/28))

### 🚀 Added

* Add missing upgradeable contracts and refactor inheritance  ([#24](https://github.com/iExec-Nox/nox-confidential-contracts/issues/24)) ([73fa08c](https://github.com/iExec-Nox/nox-confidential-contracts/commit/73fa08c2ec7270c48edb01bd45bd792b699b42b0))


### ✍️ Changed

* Fix upgradeable wrapper initialization and add tests ([#26](https://github.com/iExec-Nox/nox-confidential-contracts/issues/26)) ([29903fb](https://github.com/iExec-Nox/nox-confidential-contracts/commit/29903fb6d266cfa9c7416768c098f77a5d284242))
* Make optimized contracts as the default for token and wrapper ([#29](https://github.com/iExec-Nox/nox-confidential-contracts/issues/29)) ([445ec98](https://github.com/iExec-Nox/nox-confidential-contracts/commit/445ec98ff240a4526c23c6b0dc3ff1a13885882e))
* Rename "advanced" and "basic" contracts to use "optimized" and "raw" ([#28](https://github.com/iExec-Nox/nox-confidential-contracts/issues/28)) ([8ca08ef](https://github.com/iExec-Nox/nox-confidential-contracts/commit/8ca08eff7689d32e61114776bb92b1bd7978f44c))


### 📋 Misc

* Refactor test files hiararchy ([#27](https://github.com/iExec-Nox/nox-confidential-contracts/issues/27)) ([a83001a](https://github.com/iExec-Nox/nox-confidential-contracts/commit/a83001a76a9a9e0d7457f9afbd6c7c4780b3141e))

## 0.1.0 (2026-04-09)

This first release introduces the ERC7984 confidential token standard and its ecosystem. It covers the base implementation, transfer and `transferAndCall` support, an ERC20 wrapper with wrap/unwrap flows, advanced compute primitives integration, and an upgradeable contract variant. The project is licensed under MIT in alignment with other Nox repositories.

### 🚀 Added

* Init project ([66ea531](https://github.com/iExec-Nox/nox-confidential-contracts/commit/66ea5316566f382bd4e86681158447f44db4836e))
* ERC7984 base ([#3](https://github.com/iExec-Nox/nox-confidential-contracts/issues/3)) ([30a3638](https://github.com/iExec-Nox/nox-confidential-contracts/commit/30a3638c288ad08f0a540709e18cdd64244692e4))
* ERC7984 transfers ([#4](https://github.com/iExec-Nox/nox-confidential-contracts/issues/4)) ([7970216](https://github.com/iExec-Nox/nox-confidential-contracts/commit/7970216433537cc49fd79cbf72e2f0a74e475659))
* ERC7984 `transferAndCall` ([#6](https://github.com/iExec-Nox/nox-confidential-contracts/issues/6)) ([07856eb](https://github.com/iExec-Nox/nox-confidential-contracts/commit/07856eb4398cc13261cdfcd3ae5e353ac54de578))
* ERC7984 ERC20 wrapper ([#8](https://github.com/iExec-Nox/nox-confidential-contracts/issues/8)) ([eedd08f](https://github.com/iExec-Nox/nox-confidential-contracts/commit/eedd08feb5e09a7f4b9174d813ca2df250ffeebf))
* Implement ERC7984 with advanced functions ([#10](https://github.com/iExec-Nox/nox-confidential-contracts/issues/10)) ([11f4be3](https://github.com/iExec-Nox/nox-confidential-contracts/commit/11f4be326e5895e171c124ff90e22fffd19f0991))
* Implement ERC7984 to ERC20 wrapper with advanced primitives ([#11](https://github.com/iExec-Nox/nox-confidential-contracts/issues/11)) ([e8281d7](https://github.com/iExec-Nox/nox-confidential-contracts/commit/e8281d73717f9b605e36e0df857f71eb4b199e13))
* Implement `finalizeUnwrap` ([#12](https://github.com/iExec-Nox/nox-confidential-contracts/issues/12)) ([8e1c6bf](https://github.com/iExec-Nox/nox-confidential-contracts/commit/8e1c6bf8ffaed5c2e205213faa22f82a3b914921))
* Refactor and add upgradeable ERC7984 contract ([#17](https://github.com/iExec-Nox/nox-confidential-contracts/issues/17)) ([a3955d2](https://github.com/iExec-Nox/nox-confidential-contracts/commit/a3955d26e2505f9473e31e5b451ea718132fe189))


### ✍️ Changed

* Use latest Nox protocol version ([#9](https://github.com/iExec-Nox/nox-confidential-contracts/issues/9)) ([9909ab4](https://github.com/iExec-Nox/nox-confidential-contracts/commit/9909ab42bdc90f9f87d842ea4897cfe1ca729fd9))
* Remove duplicate amount from `finalizeUnwrap` ([#13](https://github.com/iExec-Nox/nox-confidential-contracts/issues/13)) ([eb0099d](https://github.com/iExec-Nox/nox-confidential-contracts/commit/eb0099d5ea45a8bdfa1c500a499e02df48849d67))
* Remove `isInitialized` checks ([#18](https://github.com/iExec-Nox/nox-confidential-contracts/issues/18)) ([ad64aa1](https://github.com/iExec-Nox/nox-confidential-contracts/commit/ad64aa1c2c73b2886f2cfaeb829b67acbe7ef551))


### 📋 Misc

* Align with MIT license for Nox repositories ([#15](https://github.com/iExec-Nox/nox-confidential-contracts/issues/15)) ([1ea77ef](https://github.com/iExec-Nox/nox-confidential-contracts/commit/1ea77ef22105c3d9807f2e7cc4e1db4cefc35787))
* Upload SARIF report ([#16](https://github.com/iExec-Nox/nox-confidential-contracts/issues/16)) ([38a54af](https://github.com/iExec-Nox/nox-confidential-contracts/commit/38a54afa815f1ec016b9c753997faced7fba4620))
* Update readme & dependencies ([#21](https://github.com/iExec-Nox/nox-confidential-contracts/issues/21)) ([29aa1a8](https://github.com/iExec-Nox/nox-confidential-contracts/commit/29aa1a81f0eb99ec073f53676fe298855963b7d0))
