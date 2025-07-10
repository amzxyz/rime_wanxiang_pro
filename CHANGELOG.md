# Changelog

## [8.7.0](https://github.com/amzxyz/rime_wanxiang/compare/v8.6.2...v8.7.0) (2025-07-10)


### ✨ 新特性

* 新增通用简码库 ([d63cb60](https://github.com/amzxyz/rime_wanxiang/commit/d63cb60bddabdcc37afe5b4bc352c77419c6ce12))
* 时间Lua新增适当的tips，取消个别首选注释 ([a83e511](https://github.com/amzxyz/rime_wanxiang/commit/a83e5114679bf0f2f5519554df72cff967accc37))


### 📚 词库更新

* 删减词条 ([078f9bf](https://github.com/amzxyz/rime_wanxiang/commit/078f9bf31b31bf08b00f482c3233d961331ccbff))
* 词库删改 ([d495937](https://github.com/amzxyz/rime_wanxiang/commit/d495937e2d0e135ada77bf021110d198691c28db))
* 词库调整 ([76ea067](https://github.com/amzxyz/rime_wanxiang/commit/76ea067130dd5beca9992daa361ee2cad3db5605))


### 🐛 Bug 修复

* **lua:** sequence /指令排序会影响/symbol的问题 ([88eddac](https://github.com/amzxyz/rime_wanxiang/commit/88eddac686a53bc69449949188f3007d4e28317a)), closes [#206](https://github.com/amzxyz/rime_wanxiang/issues/206)
* 词库去重 ([ae85cc0](https://github.com/amzxyz/rime_wanxiang/commit/ae85cc0864075e4d8d3970ec1fb92bc10716bec0))

## [8.6.2](https://github.com/amzxyz/rime_wanxiang/compare/v8.6.1...v8.6.2) (2025-07-09)


### 📚 词库更新

* 删减无用词条 ([59875d3](https://github.com/amzxyz/rime_wanxiang/commit/59875d3f24b19f6011322fc20d21b8d809a83f20))
* 词库调整 ([768384a](https://github.com/amzxyz/rime_wanxiang/commit/768384ad89e2f802f708de199df0529d4fb9447d))
* 词库调整 ([9562e98](https://github.com/amzxyz/rime_wanxiang/commit/9562e989d634bd4c3c569fc04d1eee012960e7b8))


### 🐛 Bug 修复

* **lua:** sequence 规避小狼毫和仓输入法的 user_id 不正确的问题 ([1b49bf5](https://github.com/amzxyz/rime_wanxiang/commit/1b49bf5f70c3c47c1b43c583dff6255097f38abe))
* **lua:** sequence 重置操作的同步支持 ([68fee1f](https://github.com/amzxyz/rime_wanxiang/commit/68fee1fc7b8242e6bcdb4ba62cc3fcd49189ba6a))


### 🏡 杂项

* readme完善 ([756564f](https://github.com/amzxyz/rime_wanxiang/commit/756564f8e0b1e8476c24462a4acac19b546d2b40))
* 简码词库放入jmdict文件夹 ([bd57576](https://github.com/amzxyz/rime_wanxiang/commit/bd575765019b20f4f80045063980504ac94fcbd9))


### 🤖 持续集成

* fix ci release note use google/release-please ([48ea3aa](https://github.com/amzxyz/rime_wanxiang/commit/48ea3aa09d00a7ec0ff99716bfb92be41b8af5be))
* 打包方案时忽略 release-please 配置 ([4b64314](https://github.com/amzxyz/rime_wanxiang/commit/4b6431470aa1df4823824c74da4cc877047d9002))
